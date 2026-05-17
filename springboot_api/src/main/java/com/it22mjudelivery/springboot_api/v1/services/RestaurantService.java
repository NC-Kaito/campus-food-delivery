package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;

public interface RestaurantService {
    Restaurant doLoginRestaurant(String username, String password);
    boolean doRegisterRestaurant(RestaurantDto restaurantDto);
}
