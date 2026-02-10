
import 'package:flutter/material.dart';
import 'package:needsfine_app/services/feed_service.dart';

class ReportDialog extends StatefulWidget {
  final String targetType; // 'post', 'comment', etc.
  final int targetId;

  const ReportDialog({super.key, required this.targetType, required this.targetId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final List<String> _reasons = [
    '스팸/광고',
    '욕설/비하 발언',
    '음란물/부적절한 콘텐츠',
    '도배',
    '주제와 무관함',
    '기타',
  ];
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    try {
      await FeedService.reportPost(
        postId: widget.targetId,
        reason: _selectedReason!,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFFC87CFF), size: 48),
              SizedBox(height: 16),
              Text("신고가 접수되었습니다.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text("운영팀에서 24시간 이내에 검토하겠습니다.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인", style: TextStyle(color: Color(0xFFC87CFF), fontWeight: FontWeight.bold)),
            )
          ],
        )
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신고 접수 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.all(24),
      title: const Center(
        child: Text("신고하기", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "신고 사유를 선택해주세요.\n허위 신고 시 불이익을 받을 수 있습니다.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = reason),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFC87CFF).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFFC87CFF) : Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Text(reason, style: TextStyle(
                        fontSize: 14, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFC87CFF) : Colors.black87
                      )),
                      const Spacer(),
                      if (isSelected) const Icon(Icons.check_rounded, color: Color(0xFFC87CFF), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (_selectedReason == '기타')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: "상세 내용을 입력해주세요 (선택)",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.grey[700],
                ),
                child: const Text("취소", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_selectedReason != null && !_isSubmitting) ? _submitReport : null,
                style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFC87CFF),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   elevation: 0,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("신고하기", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }
}
