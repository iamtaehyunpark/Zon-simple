import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'full_screen_image_viewer.dart';

/// Read-only horizontal strip of square photo thumbnails.
/// Tapping any thumbnail opens the full-screen viewer at that index.
class PhotoThumbRow extends StatelessWidget {
  final List<String> urls;
  final double size;
  const PhotoThumbRow({super.key, required this.urls, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => FullScreenImageViewer.show(context, urls, index: i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: urls[i],
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
