package com.it22mjudelivery.springboot_api.v2.dtos;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RestaurantDto {
    private String username;
    private String password;
    private String restaurantname;
    private String restaurantimage;
    private Double latitude;
    private Double longitude;
    private String imagecardid;
    private String ownerfirstname;
    private String ownerlastname;
    private String email;
    private String phone;
    private Boolean statusopen;
    private LocalDateTime registerdate;
    private String verificationstatus;
    private Integer typeid;

    private List<OpeningHourDto> openingHours;
}
