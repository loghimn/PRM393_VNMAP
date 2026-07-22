import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  // Test 1: Direct hash of "admin123"
  final bytes1 = utf8.encode('admin123');
  final hash1 = sha256.convert(bytes1);
  print('Test 1 - SHA-256 of "admin123"');
  print('  bytes: $bytes1');
  print('  digest.toString(): ${hash1.toString()}');
  print('  digest.bytes: ${hash1.bytes}');
  
  // Test 2: Build hash manually with hex encoding
  final hexHash = hash1.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  print('  manual hex: $hexHash');
  
  // Test 3: Compare with what DB expects
  print('');
  print('Expected (from DB): ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f');
  print('Got (toString):     ${hash1.toString()}');
  print('Got (manual hex):   $hexHash');
  print('Match toString: ${hash1.toString() == "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f"}');
  print('Match hex:      $hexHash == "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f"');
  
  // Test 4: Verify the actual hash
  print('');
  print('Testing actual stored hash:');
  print('  "admin123" -> SHA-256 hex: $hexHash');
}