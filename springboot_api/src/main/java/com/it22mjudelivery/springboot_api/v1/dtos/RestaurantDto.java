package com.it22mjudelivery.springboot_api.v1.dtos;

import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantDto {
    private String username;
    private String password;
    private String restaurantname;
    private String restaurantimage;
    private LocalTime opentime;
    private LocalTime closetime;
    private int openday;
    private Double latitude;
    private Double longitude;
    private String lease_agreement_img;
    private String ownerfirstname;
    private String ownerlastname;
    private String email;
    private String phone;
    private Boolean statusopen;
    private LocalDateTime registerdate;
    private String verificationstatus;
    private Integer typeid;
}
