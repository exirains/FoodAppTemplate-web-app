import 'package:hive/hive.dart';

part 'address.g.dart';

@HiveType(typeId: 2)
class Address {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? userId;
  @HiveField(2)
  final String title;
  @HiveField(3)
  final String fullAddress;
  @HiveField(4)
  final String city;
  @HiveField(5)
  final String district;
  @HiveField(6)
  final String street;
  @HiveField(7)
  final String? building;
  @HiveField(8)
  final String? floor;
  @HiveField(9)
  final String? door;
  @HiveField(10)
  final double? latitude;
  @HiveField(11)
  final double? longitude;
  @HiveField(12)
  final String? deliveryNote;

  const Address({
    this.id,
    this.userId,
    required this.title,
    required this.fullAddress,
    required this.city,
    required this.district,
    required this.street,
    this.building,
    this.floor,
    this.door,
    this.latitude,
    this.longitude,
    this.deliveryNote,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'full_address': fullAddress,
      'city': city,
      'district': district,
      'street': street,
      if (building != null) 'building': building,
      if (floor != null) 'floor': floor,
      if (door != null) 'door': door,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (deliveryNote != null) 'delivery_note': deliveryNote,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? 'Address',
      fullAddress: json['full_address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      street: json['street'] as String? ?? '',
      building: json['building'] as String?,
      floor: json['floor'] as String?,
      door: json['door'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      deliveryNote: json['delivery_note'] as String?,
    );
  }

  Address copyWith({
    String? id,
    String? userId,
    String? title,
    String? fullAddress,
    String? city,
    String? district,
    String? street,
    String? building,
    String? floor,
    String? door,
    double? latitude,
    double? longitude,
    String? deliveryNote,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      door: door ?? this.door,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deliveryNote: deliveryNote ?? this.deliveryNote,
    );
  }
}
