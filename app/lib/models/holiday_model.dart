class Holiday {
  final String id;
  final String name;
  final String date;
  final bool isRecurring;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    required this.isRecurring,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    date: json['date'] as String? ?? '',
    isRecurring: json['is_recurring'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'is_recurring': isRecurring,
  };
}
