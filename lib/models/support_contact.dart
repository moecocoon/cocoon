class SupportContact {
  final String name;
  final String category;
  final String phoneNumber;
  final String url;
  final String memo;

  const SupportContact({
    required this.name,
    required this.category,
    required this.phoneNumber,
    required this.url,
    required this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'phoneNumber': phoneNumber,
      'url': url,
      'memo': memo,
    };
  }

  factory SupportContact.fromJson(Map<String, dynamic> json) {
    return SupportContact(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      url: json['url'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
    );
  }
}