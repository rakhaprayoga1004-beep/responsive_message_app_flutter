// lib/utils/screen_presets.dart
class ScreenPreset {
  final String name;
  final String brand;
  final double width;
  final double height;
  final String icon;

  ScreenPreset({
    required this.name,
    required this.brand,
    required this.width,
    required this.height,
    required this.icon,
  });

  // Daftar preset ukuran layar populer
  static List<ScreenPreset> get presets => [
    ScreenPreset(
      name: 'iPhone SE', 
      brand: 'Apple', 
      width: 375, 
      height: 667, 
      icon: '📱'
    ),
    ScreenPreset(
      name: 'iPhone 15', 
      brand: 'Apple', 
      width: 390, 
      height: 844, 
      icon: '📱'
    ),
    ScreenPreset(
      name: 'Pixel 7', 
      brand: 'Google', 
      width: 412, 
      height: 915, 
      icon: '🤖'
    ),
    ScreenPreset(
      name: 'Galaxy S23', 
      brand: 'Samsung', 
      width: 360, 
      height: 780, 
      icon: '📱'
    ),
    ScreenPreset(
      name: 'iPad Mini', 
      brand: 'Apple', 
      width: 768, 
      height: 1024, 
      icon: '📟'
    ),
    ScreenPreset(
      name: 'iPad Pro 12.9', 
      brand: 'Apple', 
      width: 1024, 
      height: 1366, 
      icon: '📟'
    ),
    ScreenPreset(
      name: 'Desktop HD', 
      brand: 'Generic', 
      width: 1280, 
      height: 720, 
      icon: '🖥️'
    ),
    ScreenPreset(
      name: 'Desktop FHD', 
      brand: 'Generic', 
      width: 1920, 
      height: 1080, 
      icon: '🖥️'
    ),
  ];

  // Untuk ukuran custom
  static ScreenPreset customPreset(double width, double height) {
    return ScreenPreset(
      name: 'Custom', 
      brand: 'User', 
      width: width, 
      height: height, 
      icon: '⚙️'
    );
  }
}