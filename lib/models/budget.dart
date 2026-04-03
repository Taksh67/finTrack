class Budget {
  final String category;
  final double monthlyLimit;
  final double currentSpent;

  Budget({
    required this.category,
    required this.monthlyLimit,
    this.currentSpent = 0.0,
  });

  double get remaining => monthlyLimit - currentSpent;
  double get percentageSpent => monthlyLimit > 0 ? currentSpent / monthlyLimit : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
      'currentSpent': currentSpent,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      category: map['category'],
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      currentSpent: (map['currentSpent'] as num).toDouble(),
    );
  }
}
