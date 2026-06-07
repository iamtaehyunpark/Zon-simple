import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/photos/photo_service.dart';

part 'photo_suggestion_provider.g.dart';

/// Today's geotagged photos — surfaced as check-in suggestions.
@riverpod
Future<List<AssetEntity>> todayPhotoSuggestions(
    TodayPhotoSuggestionsRef ref) async {
  return PhotoService().getNewPhotosToday();
}
