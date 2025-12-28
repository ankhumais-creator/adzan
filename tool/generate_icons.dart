import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading icon from assets/icon.png...');
  final sourceFile = File('assets/icon.png');
  if (!await sourceFile.exists()) {
    print('ERROR: assets/icon.png not found!');
    return;
  }
  
  final bytes = await sourceFile.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('ERROR: Could not decode image');
    return;
  }
  
  print('Original size: ${image.width}x${image.height}');
  
  // Define sizes for different densities
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  for (var entry in sizes.entries) {
    final folder = entry.key;
    final size = entry.value;
    
    print('Creating $folder/ic_launcher.png (${size}x$size)...');
    
    final resized = img.copyResize(image, width: size, height: size);
    final pngBytes = img.encodePng(resized);
    
    final outputPath = 'android/app/src/main/res/$folder/ic_launcher.png';
    await File(outputPath).writeAsBytes(pngBytes);
    print('  Written to $outputPath');
  }
  
  // Also create foreground icons (larger for adaptive icons)
  final foregroundSizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
  };
  
  for (var entry in foregroundSizes.entries) {
    final folder = entry.key;
    final size = entry.value;
    
    print('Creating $folder/ic_launcher_foreground.png (${size}x$size)...');
    
    final resized = img.copyResize(image, width: size, height: size);
    final pngBytes = img.encodePng(resized);
    
    final outputPath = 'android/app/src/main/res/$folder/ic_launcher_foreground.png';
    await File(outputPath).writeAsBytes(pngBytes);
    print('  Written to $outputPath');
    
    // Also create monochrome
    final monoPath = 'android/app/src/main/res/$folder/ic_launcher_monochrome.png';
    await File(monoPath).writeAsBytes(pngBytes);
    print('  Written to $monoPath');
  }
  
  print('Done!');
}
