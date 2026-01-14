import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StepBirth extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const StepBirth({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.light),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: selectedDate,
          minimumDate: DateTime(1900),
          maximumDate: DateTime.now(),
          onDateTimeChanged: onDateChanged,
          use24hFormat: true,
          dateOrder: DatePickerDateOrder.ymd,
        ),
      ),
    );
  }
}
