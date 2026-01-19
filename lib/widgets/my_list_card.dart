import 'package:flutter/material.dart';
import 'package:needsfine_app/models/my_list_models.dart';

class MyListCard extends StatelessWidget {
  final MyList list;
  final List<SavedStore> savedStores;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const MyListCard({
    super.key,
    required this.list,
    required this.savedStores,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final storesById = {for (final s in savedStores) s.id: s};
    final previewNames = list.storeIds
        .map((id) => storesById[id]?.name)
        .whereType<String>()
        .take(3)
        .toList();

    final count = list.storeIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 제목 + ⋯
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MoreMenu(
                  onDelete: onDelete,
                  onShare: onShare,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 카운트
            Text(
              "총 $count개 매장",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B6F),
              ),
            ),

            if (previewNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: previewNames
                    .map((name) => _PreviewChip(text: name))
                    .toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                "아직 선택된 매장이 없습니다.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String text;
  const _PreviewChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3A3A3C),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _MoreMenu({
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF8E8E93), size: 22),
      onSelected: (value) {
        if (value == 'delete') onDelete();
        if (value == 'share') onShare();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'share',
          child: Text("공유하기"),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text("해당 리스트 삭제하기", style: TextStyle(color: Color(0xFFD32F2F))),
        ),
      ],
    );
  }
}
