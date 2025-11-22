import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
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
    final int itemCount = 1000; 
    const double itemWidth = 100.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 40,
      child: ScrollablePositionedList.builder(
        padding: EdgeInsets.symmetric(horizontal: (screenWidth - itemWidth) / 2),
        initialScrollIndex: itemCount ~/ 2,
        itemScrollController: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final categoryIndex = index % categories.length;
          bool isSelected = currentCategoryIndex == categoryIndex;
          return SizedBox(
            width: itemWidth,
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
                      color: isSelected ? kNeedsFinePurple : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      height: 2,
                      width: 40,
                      color: kNeedsFinePurple,
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
