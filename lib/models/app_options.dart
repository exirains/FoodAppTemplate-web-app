class AppOptions {
  final int minOrderLimit;

  AppOptions({
    this.minOrderLimit = 0,
  });

  factory AppOptions.fromJson(Map<String, dynamic> json) {
    // Assuming JSON is a list of options from Supabase
    // or we've mapped it already.
    return AppOptions(
      minOrderLimit: int.tryParse(json['min_order_limit']?.toString() ?? '0') ?? 0,
    );
  }
}
