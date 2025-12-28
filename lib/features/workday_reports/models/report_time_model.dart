import 'package:equatable/equatable.dart';

class ReportTimeModel extends Equatable {
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;

  const ReportTimeModel({
    this.startTime,
    this.endTime,
    this.duration,
  });

  // Calcular duración automáticamente
  Duration? get calculatedDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return duration;
  }

  // Formatear duración como string (HH:MM)
  String get durationFormatted {
    final dur = calculatedDuration;
    if (dur == null) return '--:--';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  factory ReportTimeModel.fromJson(Map<String, dynamic> json) {
    return ReportTimeModel(
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String)
          : null,
      duration: json['duration'] != null
          ? Duration(minutes: json['duration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration': calculatedDuration?.inMinutes,
    };
  }

  ReportTimeModel copyWith({
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
  }) {
    return ReportTimeModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [startTime, endTime, duration];
}
