package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDetailCurryDto {
    private int menuId;         // รหัสเมนูกับข้าวที่เลือกราด
    private double priceAtOrder; // ราคาที่ล็อกไว้ ณ ตอนสั่ง
}