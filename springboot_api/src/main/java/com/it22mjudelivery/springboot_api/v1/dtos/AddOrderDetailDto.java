package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.*;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDetailDto {
    private int menuId;
    private int qty;
    private double subTotal;
    private String note;
    private List<AddOrderDetailAddOnDto> addons;
    private List<AddOrderDetailCurryDto> orderDetailCurries;
}
