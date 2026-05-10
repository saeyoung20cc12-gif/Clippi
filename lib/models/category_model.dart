import 'package:flutter/material.dart';

class CategoryModel {
  final String label;
  final IconData icon;
  final String group;
  final Color accentColor;

  const CategoryModel({
    required this.label,
    required this.icon,
    required this.group,
    required this.accentColor,
  });
}
