import 'package:flutter/material.dart';

class WordPair {
  final String en;
  final String ar;
  final String visual;
  const WordPair({required this.en, required this.ar, required this.visual});
}

class Level {
  final String name;
  final List<WordPair> pairs;
  const Level({required this.name, required this.pairs});
}

class Category {
  final String id;
  final String title;
  final String sub;
  final String icon;
  final Color color;
  final List<Level> levels;
  const Category({
    required this.id,
    required this.title,
    required this.sub,
    required this.icon,
    required this.color,
    required this.levels,
  });
}