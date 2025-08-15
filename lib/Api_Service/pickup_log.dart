import 'package:intl/intl.dart';

class PickupLog {
  final String logID;
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
      logID: json['logID']?.toString() ?? '',
      verifiedAt: DateTime.parse(json['verifiedAt']),
      childName: json['childName'] ?? 'Unknown',
      grade: json['grade'] ?? 'N/A',
      parentName: json['parentName'] ?? 'Unknown',
      verifiedBy: json['verifiedBy'] ?? 'Unknown',
      
    );
  }

  String get formattedTime => DateFormat('MMM d, hh:mm a').format(verifiedAt);

  get childID => null;
}