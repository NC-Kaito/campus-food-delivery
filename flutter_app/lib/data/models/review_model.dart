class ReviewSubmitModel {
  final int orderid;
  final int restaurantrating;
  final int riderrating;
  final String? commentrestaurant;
  final bool cleanliness;
  final bool tasteRating;
  final bool deliverySpeed;
  final bool foodCondition;
  final String? commentrider;

  ReviewSubmitModel({
    required this.orderid,
    required this.restaurantrating,
    required this.riderrating,
    this.commentrestaurant,
    required this.cleanliness,
    required this.tasteRating,
    required this.deliverySpeed,
    required this.foodCondition,
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
