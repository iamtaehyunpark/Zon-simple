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
