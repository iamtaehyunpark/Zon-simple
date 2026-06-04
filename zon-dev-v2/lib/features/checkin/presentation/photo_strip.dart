import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Horizontal strip for picking/previewing/removing local image files before
/// upload. Shared by the check-in and stamp editors. Works in local-path space;
/// the actual upload happens at save time.
class PhotoStrip extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  const PhotoStrip({super.key, required this.paths, required this.onChanged});

  Future<void> _add() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;
    onChanged([...paths, ...picked.map((x) => x.path)]);
  }

  void _remove(int i) => onChanged([...paths]..removeAt(i));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _add,
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Add', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          for (int i = 0; i < paths.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(paths[i]),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => _remove(i),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
