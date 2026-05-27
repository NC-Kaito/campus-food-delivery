package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDto {
    private double deliveryFee;
    private double totalPrice;
    private double latitude;
    private double longitude;
    private String addressDetail;
    private List<AddOrderDetailDto> items;

    private String memberUsername;
    private String restaurantUsername;
}
