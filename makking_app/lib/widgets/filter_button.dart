import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String label;

  FilterButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(label),
    );
  }
}
