class ShiftStore {
  final int id;
  final String name;
  final String shiftStartTime;
  final String shiftEndTime;

  ShiftStore({
    required this.id,
    required this.name,
    required this.shiftStartTime,
    required this.shiftEndTime,
  });

  factory ShiftStore.fromJson(Map<String, dynamic> json) {
    return ShiftStore(
      id: json['id'],
      name: json['name'],
      shiftStartTime: json['shift_start_time'],
      shiftEndTime: json['shift_end_time'],
    );
  }
}
