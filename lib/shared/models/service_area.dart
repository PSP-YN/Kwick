/// Service area model corresponding to public.service_areas table
class ServiceArea {
  final String id;
  final String name;
  final String city;
  final String state;
  final String? pincode;
  final bool isActive;

  const ServiceArea({
    required this.id,
    required this.name,
    this.city = 'Bengaluru',
    this.state = 'Karnataka',
    this.pincode,
    this.isActive = true,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? 'Bengaluru',
      state: json['state'] as String? ?? 'Karnataka',
      pincode: json['pincode'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_active': isActive,
    };
  }
}
