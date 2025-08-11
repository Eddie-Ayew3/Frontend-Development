import 'package:intl/intl.dart';

class PickupLog {
  final int logID;
  final DateTime verifiedAt;
  final String childName;
  final String grade;
  final String parentName;
  final String verifiedBy;

  PickupLog({
    required this.logID,
    required this.verifiedAt,
    required this.childName,
    required this.grade,
    required this.parentName,
    required this.verifiedBy,
  });

  factory PickupLog.fromJson(Map<String, dynamic> json) {
    return PickupLog(
      logID: json['logID'],
      verifiedAt: DateTime.parse(json['verifiedAt']),
      childName: json['childName'],
      grade: json['grade'],
      parentName: json['parentName'] ?? 'N/A',
      verifiedBy: json['verifiedBy'],
    );
  }

  String get formattedTime => DateFormat('MMM d, hh:mm a').format(verifiedAt);
}