class ReviewSubmitModel {
  final int orderid;
  final int restaurantrating;
  final int riderrating;
  final String? commentrestaurant;
  final bool? cleanliness;
  final bool? tasteRating;
  final bool? deliverySpeed;
  final bool? foodCondition;
  final String? commentrider;

  ReviewSubmitModel({
    required this.orderid,
    required this.restaurantrating,
    required this.riderrating,
    this.commentrestaurant,
    this.cleanliness,
    this.tasteRating,
    this.deliverySpeed,
    this.foodCondition,
    this.commentrider,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderid': orderid,
      'restaurantrating': restaurantrating,
      'riderrating': riderrating,
      'commentrestaurant': commentrestaurant,
      'cleanliness': cleanliness,
      'taste_rating': tasteRating,
      'delivery_speed': deliverySpeed,
      'food_condition': foodCondition,
      'commentrider': commentrider,
    };
  }

  factory ReviewSubmitModel.fromJson(Map<String, dynamic> json) {
    return ReviewSubmitModel(
      orderid: json['orderid'] ?? 0,
      restaurantrating: json['restaurantrating'] ?? 0,
      riderrating: json['riderrating'] ?? 0,
      commentrestaurant: json['commentrestaurant'],
      cleanliness: json['cleanliness'],
      tasteRating: json['taste_rating'],
      deliverySpeed: json['delivery_speed'],
      foodCondition: json['food_condition'],
      commentrider: json['commentrider'],
    );
  }
}
