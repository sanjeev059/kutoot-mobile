/// Bootstrap Icons (MIT) bundled under assets/category_icons/.
String categoryIconAssetPath(String rawName) {
  final n = rawName.trim().toLowerCase();
  if (n.isEmpty || n == 'all') {
    return 'assets/category_icons/grid.svg';
  }
  if (n.contains('food') ||
      n.contains('restaurant') ||
      n.contains('dining') ||
      n.contains('cafe')) {
    return 'assets/category_icons/egg-fried.svg';
  }
  if (n.contains('shopping') ||
      n.contains('retail') ||
      n.contains('fashion')) {
    return 'assets/category_icons/bag-heart.svg';
  }
  if (n.contains('health') ||
      n.contains('wellness') ||
      n.contains('beauty') ||
      n.contains('spa')) {
    return 'assets/category_icons/heart-pulse.svg';
  }
  if (n.contains('electronics') ||
      n.contains('tech') ||
      n.contains('mobile')) {
    return 'assets/category_icons/laptop.svg';
  }
  if (n.contains('entertainment') || n.contains('movie')) {
    return 'assets/category_icons/film.svg';
  }
  if (n.contains('service') || n.contains('repair')) {
    return 'assets/category_icons/tools.svg';
  }
  return 'assets/category_icons/shop.svg';
}
