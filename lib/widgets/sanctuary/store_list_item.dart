import 'package:flutter/material.dart';
import 'package:needsfine_app/models/store_model.dart';
import 'crown_painter.dart';

class StoreListItem extends StatelessWidget {
  final Store store;

  const StoreListItem({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/store-detail', arguments: '1'); // TODO: Use actual store id
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow crown to overflow
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.store, size: 60, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: -12,
                  right: 15,
                  child: _buildRankBadge(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        store.needsFineScore.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Text("(${store.reviewCount})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("현재 위치로부터 ${store.distance}km", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: store.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      backgroundColor: Colors.grey[200],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    if (store.rank <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              "${store.rank}위",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    } else {
        Color badgeColor = const Color(0xFFFEE1E1); 
        Color textColor = const Color(0xFFD32F2F); 

        return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
            Positioned(
                top: -3,
                child: CustomPaint(
                size: const Size(22, 11),
                painter: CrownPainter(color: badgeColor),
                ),
            ),
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                ),
                child: Center(
                child: Text(
                    "${store.rank}위",
                    style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                ),
                ),
            ),
            ],
        ),
        );
    }
  }
}
