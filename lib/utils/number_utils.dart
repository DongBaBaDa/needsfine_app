
import 'package:intl/intl.dart';

class NumberUtils {
  static String format(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 10000) {
      // 1,000 ~ 9,999 -> 1.x천 (e.g. 1500 -> 1.5천)
      // 소수점 1자리까지, 0이면 제거
      double val = number / 1000.0;
      return "${_formatDecimal(val)}천";
    } else {
      // 10,000+ -> 1.x만 (e.g. 15000 -> 1.5만, 100000 -> 10.0만)
      double val = number / 10000.0;
      return "${_formatDecimal(val)}만";
    }
  }

  static String _formatDecimal(double val) {
    // 소수점 1자리까지 표시하되, .0 이면 제거하거나 유지?
    // Request: "1.0만개, 10.0만개" -> 1.0 is kept using toStringAsFixed(1)
    return val.toStringAsFixed(1); 
  }
}
