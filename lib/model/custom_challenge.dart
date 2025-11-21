class CustomChallenge {
  final String name;
  final String unit;
  final int target;
  final int current;
  
  CustomChallenge({
    required this.name,
    required this.unit,
    required this.target,
    this.current = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'unit': unit,
    'target': target,
    'current': current,
  };
  
  factory CustomChallenge.fromJson(Map<String, dynamic> json) =>
      CustomChallenge(
        name: json['name'],
        unit: json['unit'],
        target: json['target'],
        current: json['current'] ?? 0,
      );
  
  CustomChallenge copyWith({
    String? name,
    String? unit,
    int? target,
    int? current,
  }) {
    return CustomChallenge(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      target: target ?? this.target,
      current: current ?? this.current,
    );
  }
}
