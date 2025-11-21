import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CategoryList extends StatelessWidget {
  final ItemScrollController scrollController;
  final int currentCategoryIndex;
  final List<String> categories;
  final Function(int) onCategoryTapped;

  const CategoryList({
    super.key,
    required this.scrollController,
    required this.currentCategoryIndex,
    required this.categories,
    required this.onCategoryTapped,
  });

  @override
  Widget build(BuildContext context) {
    final int itemCount = 1000; // A large number for infinite scroll effect
    const double itemWidth = 100.0; // Fixed width for each category item

    return SizedBox(
      height: 40,
      child: ScrollablePositionedList.builder(
        initialScrollIndex: itemCount ~/ 2,
        itemScrollController: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final categoryIndex = index % categories.length;
          bool isSelected = currentCategoryIndex == categoryIndex;
          return SizedBox(
            width: itemWidth, // Apply fixed width
            child: GestureDetector(
              onTap: () => onCategoryTapped(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categories[categoryIndex],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 40,
                      color: Colors.blue,
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
