package com.it22mjudelivery.springboot_api.v2.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDetailDto {
    private int menuId;
    private String menuNameAtOrder;
    private double priceAtOrder;
    private int qty;
    private double subTotal;
    private String note;
    private List<AddOrderDetailAddOnDto> addons;
    private List<AddOrderDetailCurryDto> orderDetailCurries;
}
