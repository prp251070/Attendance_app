// lib/utils/helpers.dart

/// Capitalize the first letter of every word
String capitalizeWords(String name) {
  return name
      .split(' ')
      .map((word) => word.isEmpty
      ? word
      : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
