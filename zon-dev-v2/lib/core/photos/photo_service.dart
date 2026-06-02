import 'dart:io';
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

  /// Upload a photo to Supabase Storage and return its public URL.
  Future<String?> uploadPhoto(AssetEntity asset) async {
    try {
      final file = await asset.originFile;
      if (file == null) return null;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return null;

      // Compress before upload
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
          .from('photos')
          .upload(filename, uploadFile);

      final url = Supabase.instance.client.storage
          .from('photos')
          .getPublicUrl(filename);

      return url;
    } catch (_) {
      return null;
    }
  }

  /// Process a single asset: upload it and call ingest-photo-exif edge function.
  Future<void> processAsset(AssetEntity asset) async {
    final latLng = await asset.latlngAsync();
    if (latLng == null) return;
    if (latLng.latitude == 0.0 && latLng.longitude == 0.0) return;

    final url = await uploadPhoto(asset);
    if (url == null) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    await Supabase.instance.client.functions.invoke(
      'ingest-photo-exif',
      body: {
        'storage_url': url,
        'exif_lat': latLng.latitude,
        'exif_lng': latLng.longitude,
        'exif_taken_at': (asset.createDateTime).toIso8601String(),
        'width': asset.width,
        'height': asset.height,
      },
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
  }
}
