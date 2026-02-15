import 'package:flutter/material.dart';

class OperatingHoursSelector extends StatefulWidget {
  final Map<String, dynamic>? initialValue;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const OperatingHoursSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<OperatingHoursSelector> createState() => _OperatingHoursSelectorState();
}

class _OperatingHoursSelectorState extends State<OperatingHoursSelector> {
  // Structure: 
  // {
  //   'mon': { 'open': '09:00', 'close': '22:00', 'break_start': null, 'break_end': null, 'is_closed': false },
  //   ...
  //   'holidays': 'Every Monday', // Example text
  // }
  
  late Map<String, dynamic> _hoursData;
  final List<String> _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final List<String> _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  // Simplified UI: "Weekdays" vs "Weekends" or "Every Day Same" toggle?
  // User asked for "Days shown in operating hours". Let's do a per-day toggle for simplicity + bulk edit if needed.
  // Actually, a common pattern is: "Standard Hours" applied to all, then customize specific days.
  // Let's implement: 
  // 1. Regular Hours (Time Picker)
  // 2. Select Days Open (Toggle Buttons)
  // 3. Holiday Text Input

  TimeOfDay _openTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;
  
  Set<String> _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
  final TextEditingController _holidayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hoursData = widget.initialValue ?? {};
    
    // 1. Restore Times
    if (_hoursData['open'] != null) _openTime = _parseTime(_hoursData['open']);
    if (_hoursData['close'] != null) _closeTime = _parseTime(_hoursData['close']);
    if (_hoursData['break_start'] != null) _breakStart = _parseTime(_hoursData['break_start']);
    if (_hoursData['break_end'] != null) _breakEnd = _parseTime(_hoursData['break_end']);

    // 2. Restore Days
    if (_hoursData['days'] != null) {
      _selectedDays = Set<String>.from(_hoursData['days']);
    }

    // 3. Restore Holiday Text
    if (_hoursData['holidays'] != null) {
      _holidayController.text = _hoursData['holidays'];
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  void _update() {
    // Construct simplified data
    final data = {
      'open': '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}',
      'close': '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}',
      'days': _selectedDays.toList(),
      'holidays': _holidayController.text,
      'break_start': _breakStart != null ? '${_breakStart!.hour.toString().padLeft(2, '0')}:${_breakStart!.minute.toString().padLeft(2, '0')}' : null,
      'break_end': _breakEnd != null ? '${_breakEnd!.hour.toString().padLeft(2, '0')}:${_breakEnd!.minute.toString().padLeft(2, '0')}' : null,
    };
    widget.onChanged(data);
  }

  Future<void> _pickTime(bool isOpen) async {
    final initial = isOpen ? _openTime : _closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8A2BE2), // Purple
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isOpen) _openTime = picked;
        else _closeTime = picked;
      });
      _update();
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    _update();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Operating Days
        const Text('영업 요일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (index) {
            final day = _days[index];
            final isSelected = _selectedDays.contains(day);
            return GestureDetector(
              onTap: () => _toggleDay(day),
              child: Container(
                width: 40, height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8A2BE2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey.shade300),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: const Color(0xFF8A2BE2).withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
                ),
                child: Text(
                  _dayLabels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 16),
        
        // 2. Time Picker Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오픈 시간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Color(0xFF8A2BE2)),
                          const SizedBox(width: 8),
                          Text(_openTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('마감 시간', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 18, color: Color(0xFF555555)),
                          const SizedBox(width: 8),
                          Text(_closeTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Holidays
        const Text('휴무일 / 브레이크 타임', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
        const SizedBox(height: 8),
        TextField(
          controller: _holidayController,
          onChanged: (_) => _update(),
          decoration: InputDecoration(
            hintText: '예: 매주 월요일 휴무, 브레이크타임 15:00~17:00',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
