package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.Data;
import java.util.List;

@Data
public class AddonGroupRequestDTO {
    private Integer addongroupid;
    private String restaurantUsername; // ชื่อผู้ใช้ร้านค้าที่เป็นเจ้าของกลุ่มนี้
    private String addongroupname;     // ชื่อกลุ่ม เช่น "เลือกท็อปปิ้ง (ไข่)"
    private boolean isRequired;        // บังคับเลือกหรือไม่
    private int maxselect;             // เลือกได้สูงสุดกี่อย่าง
    private boolean status;            // สถานะเปิด/ปิดใช้งาน

    private List<AddonDetailDTO> details; // รายการช้อยส์ย่อยในกลุ่ม

    @Data
    public static class AddonDetailDTO {
        private Integer addondetailId;
        private String addonname;  // ชื่อวัตถุดิบ เช่น "ไข่ดาว", "ไข่เจียว"
        private double addonprice; // ราคาที่บวกเพิ่ม
        private boolean status;    // สถานะเปิด/ปิดใช้งาน
    }


}