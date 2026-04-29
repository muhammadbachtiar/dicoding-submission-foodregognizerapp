import 'package:flutter/material.dart';

class ClassificatioinItem extends StatelessWidget {
  final String item;
  final String value;
  final bool isTop;

  const ClassificatioinItem({
    super.key,
    required this.item,
    required this.value,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTop
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (isTop) ...[
            const Icon(Icons.emoji_food_beverage, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
