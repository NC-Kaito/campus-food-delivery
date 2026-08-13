package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class MenuDto {
    private Integer menuid;
    private String menuname;
    private String description;
    private String imageurl;
    private Double price;
    private boolean status;
    private String username; // restaurant
    private Integer typeMenuId;
    private String typeMenuName;

    // 🎯 เพิ่มเข้ามา: สำหรับรับ List ของ ID กลุ่มตัวเลือกที่นำมาผูกกับเมนู
    private List<Integer> addonGroupIds;

    private List<AddonGroupDto> addonGroups;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddonGroupDto {
        // 🎯 เพิ่มเข้ามา: สำหรับรับ ID กรณีส่งมาเป็นรูปแบบ Object
        private Integer addongroupid;
        private String addongroupname;
        private boolean is_multiple_choice;
        private boolean status; // 🎯 เพิ่มเข้ามารองรับค่าที่ส่งมาจาก Flutter
        private List<AddonDetailDto> details;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddonDetailDto {
        private Integer addonid;
        private String customaddonname;
        private double addonprice;
    }
}