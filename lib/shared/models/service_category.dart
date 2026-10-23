/// Service category model corresponding to public.service_categories table
class ServiceCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String iconKey;
  final bool isActive;
  final int sortOrder;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.iconKey,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      iconKey: json['icon_key'] as String? ?? 'build',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon_key': iconKey,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
