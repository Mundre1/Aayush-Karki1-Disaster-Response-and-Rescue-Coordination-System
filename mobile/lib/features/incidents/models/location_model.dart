class LocationModel {
  final int locationId;
  final double latitude;
  final double longitude;
  final String? address;
  final String? district;

  LocationModel({
    required this.locationId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.district,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int
    int parseInt(String camelKey, String snakeKey) {
      final value = json[camelKey] ?? json[snakeKey];
      if (value == null) {
        throw FormatException('Missing required field: $camelKey or $snakeKey');
      }
      if (value is int) return value;
      if (value is String) return int.parse(value);
      return value as int;
    }

    return LocationModel(
      locationId: parseInt('locationId', 'location_id'),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      district: json['district'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'district': district,
    };
  }
}
