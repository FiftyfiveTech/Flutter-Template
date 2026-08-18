class CounterRecord {
  const CounterRecord({
    required this.id,
    required this.value,
    required this.updatedAt,
  });

  final int id;
  final int value;
  final DateTime updatedAt;

  CounterRecord copyWith({
    int? id,
    int? value,
    DateTime? updatedAt,
  }) {
    return CounterRecord(
      id: id ?? this.id,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
