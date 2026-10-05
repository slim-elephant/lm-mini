import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_folder.g.dart';

@JsonSerializable()
class ChatFolder {
  /// Stored in [color] when the folder uses a custom image cover.
  static const imagePrefix = 'img:';

  final String id;
  final String name;
  /// Hex color (`#RRGGBB`) or image cover (`img:relative/path`).
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> conversationIds;
  final int sortOrder;

  ChatFolder({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.conversationIds,
    this.sortOrder = 0,
  });

  factory ChatFolder.fromJson(Map<String, dynamic> json) =>
      _$ChatFolderFromJson(json);

  Map<String, dynamic> toJson() => _$ChatFolderToJson(this);

  bool get usesImage =>
      color != null && color!.startsWith(imagePrefix) && color!.length > imagePrefix.length;

  String? get imagePath => usesImage ? color!.substring(imagePrefix.length) : null;

  Color? get parsedColor {
    final value = color;
    if (value == null || usesImage || !value.startsWith('#') || value.length < 7) {
      return null;
    }
    try {
      return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return null;
    }
  }

  static String encodeColor(Color c) {
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String encodeImage(String relativePath) => '$imagePrefix$relativePath';

  ChatFolder copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? conversationIds,
    int? sortOrder,
  }) {
    return ChatFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      conversationIds: conversationIds ?? this.conversationIds,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
