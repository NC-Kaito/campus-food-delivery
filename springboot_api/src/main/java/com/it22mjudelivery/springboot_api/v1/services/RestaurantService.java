package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.OpeningHourDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;

import java.util.List;

public interface RestaurantService {
    Restaurant doLoginRestaurant(String username, String password);
    boolean doRegisterRestaurant(RestaurantDto restaurantDto);
    Restaurant getRestaurantByUsername(String username);
    boolean updateStatusOpen(String username, boolean statusopen);

    boolean updateProfileRestaurant(
            String username, String restaurantname, String restaurantimage, int typeid,
            double latitude, double longitude,
            List<OpeningHourDto> openingHourDtos, String ownerfirstname,
            String ownerlastname, String email, String phone, String ownerimage
    );

    void doCloseAccount(String username);
}