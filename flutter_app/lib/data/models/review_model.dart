class ReviewSubmitModel {
  final int orderid;
  final int restaurantrating;
  final int riderrating;
  final String? commentrestaurant;
  final String? cleanliness;
  final String? tasteRating;
  final String? deliverySpeed;
  final String? foodCondition;
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
}
