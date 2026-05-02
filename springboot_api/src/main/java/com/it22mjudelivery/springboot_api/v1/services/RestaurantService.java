package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;

public interface RestaurantService {
    boolean doRegisterRestaurant(RestaurantDto restaurantDto);
}
