class TypeRestaurantModel {
  final int id;
  final String name;

  TypeRestaurantModel({required this.id, required this.name});

  factory TypeRestaurantModel.fromJson(Map<String, dynamic> json) {
    return TypeRestaurantModel(
      id: json['typerestaurantId'],
      name: json['typerestaurantName'],
    );
  }
}
