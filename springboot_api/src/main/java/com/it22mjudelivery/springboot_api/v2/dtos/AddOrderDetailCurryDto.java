package com.it22mjudelivery.springboot_api.v2.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDetailCurryDto {
    private int menuId;         // รหัสเมนูกับข้าวที่เลือกราด
    private double priceAtOrder; // ราคาที่ล็อกไว้ ณ ตอนสั่ง
}