class Address {
  final String id;
  final String title;
  final String details;
  final String city;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.details,
    required this.city,
    this.isDefault = false,
  });
}
