import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Photo EXIF parsing — see CLAUDE.md §6.3
// Do NOT send image bytes to server; parse EXIF on device.
// Only process photos WITH location data.
class PhotoService {
  static const _uuid = Uuid();

  Future<PermissionState> requestPermission() async {
    return PhotoManager.requestPermissionExtend();
  }

  /// Returns unprocessed photos with GPS data from the last [days] days.
  Future<List<AssetEntity>> getPhotosWithLocation({int days = 30}) async {
    final permission = await requestPermission();
    if (!permission.isAuth) return [];

    final since = DateTime.now().subtract(Duration(days: days));
    final albums = await PhotoManager.getAssetPathList(
      // Single "all photos" album — avoids the same asset appearing once per
      // album (Recents/Camera Roll/Favorites…), which caused duplicate uploads.
      onlyAll: true,
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        updateTimeCond: DateTimeCond(min: since, max: DateTime.now()),
      ),
    );

    final results = <AssetEntity>[];
    for (final album in albums) {
      final assets = await album.getAssetListRange(start: 0, end: 200);
      for (final asset in assets) {
        final latLng = await asset.latlngAsync();
        if (latLng == null) continue;
        if (latLng.latitude == 0.0 && latLng.longitude == 0.0) continue;
        results.add(asset);
      }
    }
    return results;
  }

  /// Compress + upload a local image file to a Supabase Storage [bucket];
  /// returns the public URL. Files are namespaced under the user's id (RLS).
  Future<String?> uploadFile(File file, {String bucket = 'photos'}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      final tmpDir = await getTemporaryDirectory();
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${tmpDir.path}/${_uuid.v4()}.jpg',
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );

      final uploadFile = File(compressed?.path ?? file.absolute.path);
      final filename = '$userId/${_uuid.v4()}.jpg';

      await Supabase.instance.client.storage
          .from(bucket)
          .upload(filename, uploadFile);

      return Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(filename);
    } catch (_) {
      return null;
    }
  }

  /// Download [url], compress to ≤ 512 px, and return a base64-encoded JPEG
  /// string. The resized bytes are never written to disk or stored — they exist
  /// only in memory for the duration of the LLM call.
  ///
  /// Returns null on any network or compression failure.
  static Future<String?> resizeForLlm(String url) async {
    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        minWidth: 512,
        minHeight: 512,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      return base64Encode(compressed);
    } catch (_) {
      return null;
    }
  }

  /// Geotagged photos taken *today* — the basis for check-in suggestions.
  Future<List<AssetEntity>> getNewPhotosToday() async {
    final all = await getPhotosWithLocation(days: 1);
    final now = DateTime.now();
    return all.where((a) {
      final d = a.createDateTime;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

}
