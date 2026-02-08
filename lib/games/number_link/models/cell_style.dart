enum CellStyle {
  numbered,     // Default: Numbers on terminal cells (a=1, b=2, c=3, etc.)
  square,       // Simple colored cell with white square for terminals
  strip,        // Terminal cells have white bordered square (5x5 with 1px border) - Unlock at level 11
  glow,         // Glow skin with images based on neighbor conditions - Unlock at level 31
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
      case CellStyle.glow:
        return 'Glow';
    }
  }
}
