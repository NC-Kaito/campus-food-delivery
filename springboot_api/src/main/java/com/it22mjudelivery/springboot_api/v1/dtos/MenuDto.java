package com.it22mjudelivery.springboot_api.v1.dtos;

import com.fasterxml.jackson.annotation.JsonAlias;
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
    private Double price2;
    private Double price3;
    private boolean status;
    private String username; // restaurant
    private Integer typeMenuId;
    private String typeMenuName;

    private List<Integer> addonGroupIds;
    private List<AddonGroupDto> addonGroups;

    // 🎯 เพิ่มฟิลด์นี้เพื่อให้รองรับก้อน optionGroups จาก Flutter
    @JsonAlias({"optionGroups", "optiongroups"})
    private List<OptionGroupRequestDTO> optionGroups;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddonGroupDto {
        private Integer addongroupid;
        private String addongroupname;
        private boolean is_multiple_choice;
        private boolean status;
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