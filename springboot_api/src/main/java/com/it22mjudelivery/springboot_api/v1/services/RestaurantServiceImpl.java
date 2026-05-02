package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RestaurantServiceImpl implements RestaurantService{
    private final RestaurantRepository restaurantRepository;

    public boolean doRegisterRestaurant(RestaurantDto restaurantDto){
        if (restaurantRepository.existsByUsername(restaurantDto.getUsername())) {
            throw new RuntimeException("ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว");
        }
        Restaurant toSaveRestaurant = Restaurant.builder()
                .username(restaurantDto.getUsername())
                .password(restaurantDto.getPassword())
                .restaurantname(restaurantDto.getRestaurantname())
                .typerestaurant(restaurantDto.getTyperestaurant())
                .latitude(restaurantDto.getLatitude())
                .longitude(restaurantDto.getLongitude())
                .restaurantimage(restaurantDto.getRestaurantimage())
                .lease_agreement_img(restaurantDto.getLease_agreement_img())
                .opentime(restaurantDto.getOpentime())
                .closetime(restaurantDto.getClosetime())
                .openDay(restaurantDto.getOpenday())
                .ownerfirstname(restaurantDto.getOwnerfirstname())
                .ownerlastname(restaurantDto.getOwnerlastname())
                .email(restaurantDto.getEmail())
                .phone(restaurantDto.getPhone())
                .build();

        restaurantRepository.save(toSaveRestaurant);
        return true;
    }
}
