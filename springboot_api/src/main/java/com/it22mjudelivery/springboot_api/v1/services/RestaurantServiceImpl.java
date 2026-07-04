package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Service
@RequiredArgsConstructor
public class RestaurantServiceImpl implements RestaurantService{
    private final RestaurantRepository restaurantRepository;
    private final TypeRestaurantRepository typeRestaurantRepository;

    public Restaurant doLoginRestaurant(String username, String password) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"));

        if (!restaurant.getPassword().equals(password)) {
            throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
        }
        return restaurant;
    }

    public boolean doRegisterRestaurant(RestaurantDto restaurantDto){
        if (restaurantRepository.existsByUsername(restaurantDto.getUsername())) {
            throw new RuntimeException("ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว");
        }
        TypeRestaurant typeRestaurant = typeRestaurantRepository.findById(restaurantDto.getTypeid())
                .orElseThrow(() -> new RuntimeException("ไม่พบประเภทร้านค้า"));

        Restaurant toSaveRestaurant = Restaurant.builder()
                .username(restaurantDto.getUsername())
                .password(restaurantDto.getPassword())
                .restaurantname(restaurantDto.getRestaurantname())
                .typerestaurant(typeRestaurant)
                .latitude(restaurantDto.getLatitude())
                .longitude(restaurantDto.getLongitude())
                .restaurantimage(restaurantDto.getRestaurantimage())
                .imagecardid(restaurantDto.getImagecardid())
                .opentime(restaurantDto.getOpentime())
                .closetime(restaurantDto.getClosetime())
                .openDay(restaurantDto.getOpenday())
                .ownerfirstname(restaurantDto.getOwnerfirstname())
                .ownerlastname(restaurantDto.getOwnerlastname())
                .email(restaurantDto.getEmail())
                .phone(restaurantDto.getPhone())
                .registerdate(LocalDateTime.now())
                .statusopen(false)
                .verificationstatus("wait")
                .build();

        restaurantRepository.save(toSaveRestaurant);
        return true;
    }

    public Restaurant getRestaurantByUsername(String username){
        Restaurant restaurant = restaurantRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        return restaurant;
    }

    public boolean updateStatusOpen(String username, boolean statusopen){
        Restaurant restaurant = restaurantRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        restaurant.setStatusopen(statusopen);
        restaurantRepository.save(restaurant);
        return true;
    }

    public boolean updateProfileRestaurant(String username, String restaurantname, String restaurantimage,
                                           int typeid,
                                           double latitude, double longitude,
                                           LocalTime opentime,
                                           LocalTime closetime, int openday, String ownerfirstname,
                                           String ownerlastname, String email, String phone, String ownerimage) {

        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        TypeRestaurant typeRestaurant = typeRestaurantRepository.findById(typeid)
                .orElseThrow(() -> new RuntimeException("ไม่พบประเภทร้านค้าที่ระบุ"));

        restaurant.setRestaurantname(restaurantname);
        restaurant.setTyperestaurant(typeRestaurant);

        restaurant.setRestaurantimage(restaurantimage);
        restaurant.setLatitude(latitude);
        restaurant.setLongitude(longitude);
        restaurant.setOpentime(opentime);
        restaurant.setClosetime(closetime);
        restaurant.setOpenDay(openday);
        restaurant.setOwnerfirstname(ownerfirstname);
        restaurant.setOwnerlastname(ownerlastname);
        restaurant.setEmail(email);
        restaurant.setPhone(phone);
        restaurant.setImagecardid(ownerimage);

        restaurantRepository.save(restaurant);
        return true;
    }


    public void doCloseAccount(String username) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));
        restaurant.setVerificationstatus("close");
        restaurant.setNotapprovedetail(null);
        restaurantRepository.save(restaurant);
    }

}
