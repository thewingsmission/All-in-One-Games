enum CellStyle {
  numbered,     // Default: Numbers on terminal cells (a=1, b=2, c=3, etc.)
  square,       // Simple colored cell with white square for terminals
  strip,        // Terminal cells have white bordered square (5x5 with 1px border) - Unlock at level 11
  glow,         // Glow skin with images based on neighbor conditions - Unlock at level 31
  animal,       // Terminal cells display an animal image - Unlock at level 51
  cat,          // Terminal cells display cat images - Unlock at level 71
  dog,          // Terminal cells display dog images - Unlock at level 91
  ghost,        // Terminal cells display ghost images - Unlock at level 111
  monster,      // Terminal cells display monster images - Unlock at level 131
}

extension CellStyleExtension on CellStyle {
  String get displayName {
    switch (this) {
      case CellStyle.numbered:
        return 'Number';
      case CellStyle.square:
        return 'Square';
      case CellStyle.strip:
        return 'Strip';
      case CellStyle.animal:
        return 'Animal';
      case CellStyle.cat:
        return 'Cat';
      case CellStyle.dog:
        return 'Dog';
      case CellStyle.ghost:
        return 'Ghost';
      case CellStyle.monster:
        return 'Monster';
      case CellStyle.glow:
        return 'Glow';
    }
  }
}
