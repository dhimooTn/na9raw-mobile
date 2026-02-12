import 'package:flutter/material.dart';

class CourseMaterial {
  final String name;
  final MaterialType type;
  final String size;
  final Color color;
  final IconData icon;
  final String url;

  CourseMaterial({
    required this.name,
    required this.type,
    required this.size,
    required this.color,
    required this.icon,
    this.url = '',
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last, // 'file', 'video', ou 'link'
      'size': size,
      'url': url,
      'colorValue': color.value, // Sauvegarder la valeur de la couleur
      'iconCodePoint': icon.codePoint, // Sauvegarder le code point de l'icône
    };
  }

  // Créer depuis Map (récupération depuis Firestore)
  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    // Déterminer le type
    MaterialType type;
    switch (map['type']) {
      case 'video':
        type = MaterialType.video;
        break;
      case 'link':
        type = MaterialType.link;
        break;
      default:
        type = MaterialType.file;
    }

    // Récupérer la couleur ou utiliser une couleur par défaut
    Color color;
    if (map['colorValue'] != null) {
      color = Color(map['colorValue']);
    } else {
      color = type == MaterialType.video
          ? Colors.blue
          : type == MaterialType.link
          ? Colors.green
          : Colors.red;
    }

    // Récupérer l'icône ou utiliser une icône par défaut
    IconData icon;
    if (map['iconCodePoint'] != null) {
      icon = IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons');
    } else {
      icon = type == MaterialType.video
          ? Icons.play_circle
          : type == MaterialType.link
          ? Icons.link
          : Icons.picture_as_pdf;
    }

    return CourseMaterial(
      name: map['name'] ?? '',
      type: type,
      size: map['size'] ?? 'Online',
      color: color,
      icon: icon,
      url: map['url'] ?? '',
    );
  }

  // Méthode pour créer une copie avec modifications
  CourseMaterial copyWith({
    String? name,
    MaterialType? type,
    String? size,
    Color? color,
    IconData? icon,
    String? url,
  }) {
    return CourseMaterial(
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      url: url ?? this.url,
    );
  }

  // Factory constructors pour créer facilement des matériaux spécifiques
  factory CourseMaterial.file({
    required String name,
    required String url,
    String size = 'Online',
  }) {
    return CourseMaterial(
      name: name,
      type: MaterialType.file,
      size: size,
      color: Colors.red,
      icon: Icons.picture_as_pdf,
      url: url,
    );
  }

  factory CourseMaterial.video({
    required String name,
    required String url,
    String size = 'Online',
  }) {
    return CourseMaterial(
      name: name,
      type: MaterialType.video,
      size: size,
      color: Colors.blue,
      icon: Icons.play_circle,
      url: url,
    );
  }

  factory CourseMaterial.link({
    required String name,
    required String url,
    String size = 'Online',
  }) {
    return CourseMaterial(
      name: name,
      type: MaterialType.link,
      size: size,
      color: Colors.green,
      icon: Icons.link,
      url: url,
    );
  }

  @override
  String toString() {
    return 'CourseMaterial(name: $name, type: $type, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseMaterial &&
        other.name == name &&
        other.type == type &&
        other.url == url;
  }

  @override
  int get hashCode {
    return name.hashCode ^ type.hashCode ^ url.hashCode;
  }
}

enum MaterialType {
  file,
  video,
  link
}

// Extension pour obtenir des labels lisibles
extension MaterialTypeExtension on MaterialType {
  String get label {
    switch (this) {
      case MaterialType.file:
        return 'File';
      case MaterialType.video:
        return 'Video';
      case MaterialType.link:
        return 'Link';
    }
  }

  IconData get icon {
    switch (this) {
      case MaterialType.file:
        return Icons.picture_as_pdf;
      case MaterialType.video:
        return Icons.play_circle;
      case MaterialType.link:
        return Icons.link;
    }
  }

  Color get color {
    switch (this) {
      case MaterialType.file:
        return Colors.red;
      case MaterialType.video:
        return Colors.blue;
      case MaterialType.link:
        return Colors.green;
    }
  }
}