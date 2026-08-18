import '../../domain/entities/counter_record.dart';

class CounterDto {
  const CounterDto({
    required this.id,
    required this.value,
    required this.updatedAt,
  });

  final int id;
  final int value;
  final DateTime updatedAt;

  factory CounterDto.fromJson(Map<String, dynamic> json) {
    return CounterDto(
      id: json['id'] as int? ?? 1,
      value: json['value'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CounterRecord toEntity() {
    return CounterRecord(
      id: id,
      value: value,
      updatedAt: updatedAt,
    );
  }

  factory CounterDto.fromEntity(CounterRecord entity) {
    return CounterDto(
      id: entity.id,
      value: entity.value,
      updatedAt: entity.updatedAt,
    );
  }
}
