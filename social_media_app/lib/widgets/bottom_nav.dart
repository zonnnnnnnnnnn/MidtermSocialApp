import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// This is a custom widget for the main bottom navigation bar of the app.
// It is a StatelessWidget, which means it doesn't manage any of its own state.
// It simply displays itself based on the data it is given.
class BottomNav extends StatelessWidget {
  // It receives the index of the currently active screen.
  final int currentIndex;
  // It receives a function to call when one of its items is tapped.
  // This is how it communicates back to its parent widget (the MainShell).
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // This is the list of icons that will be displayed in the navigation bar.
    final items = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.add_box_rounded, // The middle "create" button
      Icons.person_rounded,
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      // We use List.generate to create a button for each icon in our list.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          // We check if the current item is the selected one.
          final selected = i == currentIndex;
          return GestureDetector(
            // When tapped, we call the `onTap` function that was passed in,
            // sending back the index of the item that was tapped.
            onTap: () => onTap(i),
            // An AnimatedContainer provides a smooth visual transition when an
            // item is selected or deselected.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                items[i],
                color: selected ? AppTheme.accent : AppTheme.textSecondary,
                size: selected ? 26 : 22,
              ),
            ),
          );
        }),
      ),
    );
  }
}
