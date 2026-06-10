enum LocationSource {
  gps,
  exif,
  cellTower;

  static LocationSource fromString(String s) => switch (s) {
        'exif' => LocationSource.exif,
        'cell_tower' => LocationSource.cellTower,
        'cellTower' => LocationSource.cellTower,
        _ => LocationSource.gps,
      };

  String get dbValue => switch (this) {
        LocationSource.cellTower => 'cell_tower',
        _ => name,
      };
}

enum StampVisibility { private, public }

/// Preset "vibe" tags offered when creating or editing a stamp.
const kSensoryTags = <String>[
  'Cozy', 'Lively', 'Quiet', 'Scenic', 'Crowded',
  'Romantic', 'Family-friendly', 'Trendy', 'Historic', 'Hidden gem',
];
