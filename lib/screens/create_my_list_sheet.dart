import 'package:flutter/material.dart';
import 'package:needsfine_app/models/my_list_models.dart';

class CreateMyListSheet extends StatefulWidget {
  final List<SavedStore> savedStores;

  const CreateMyListSheet({
    super.key,
    required this.savedStores,
  });

  @override
  State<CreateMyListSheet> createState() => _CreateMyListSheetState();
}

class _CreateMyListSheetState extends State<CreateMyListSheet> {
  final _nameCtrl = TextEditingController();
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("리스트 이름을 입력하세요.")),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("저장한 매장을 1개 이상 선택하세요.")),
      );
      return;
    }

    Navigator.pop(context, _CreateListResult(name: name, storeIds: _selected.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final stores = widget.savedStores;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 핸들 + 타이틀
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "새 리스트",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 이름 입력
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: "리스트 이름",
                hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 저장한 매장 선택
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "저장한 매장 선택 (${_selected.length}/${stores.length})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3A3A3C),
                ),
              ),
            ),
            const SizedBox(height: 10),

            if (stores.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  "저장한 매장이 아직 없습니다.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = stores[index];
                    final selected = _selected.contains(s.id);
                    return _StoreSelectRow(
                      store: s,
                      selected: selected,
                      onTap: () => _toggle(s.id),
                    );
                  },
                ),
              ),

            const SizedBox(height: 14),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "리스트 만들기",
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreSelectRow extends StatelessWidget {
  final SavedStore store;
  final bool selected;
  final VoidCallback onTap;

  const _StoreSelectRow({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF7C4DFF) : const Color(0xFFE5E5EA);
    final bgColor = selected ? const Color(0xFFF4F0FF) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF7C4DFF) : const Color(0xFFF2F2F7),
                border: Border.all(color: selected ? const Color(0xFF7C4DFF) : const Color(0xFFE5E5EA)),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  if ((store.address ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      store.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateListResult {
  final String name;
  final List<String> storeIds;

  _CreateListResult({
    required this.name,
    required this.storeIds,
  });
}
