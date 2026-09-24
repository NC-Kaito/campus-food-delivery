package com.it22mjudelivery.springboot_api.v2.dtos;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AddOrderDetailAddOnDto {
    private int addondetailid;
    private String addonNameAtOrder; // 🎯 เพิ่มฟิลด์ชื่อ Add-on Snapshot
    private double priceAtOrder;     // 🎯 เพิ่มฟิลด์ราคา Add-on Snapshot
    private int addon_qty;
}