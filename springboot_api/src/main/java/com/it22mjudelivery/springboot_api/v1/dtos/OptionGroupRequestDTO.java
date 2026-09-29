package com.it22mjudelivery.springboot_api.v1.dtos;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OptionGroupRequestDTO {

    @JsonAlias({"optiongroupid", "addongroupid"})
    private Integer optiongroupid;

    // ผูกกับเมนูตาม Entity Optiongroup
    private Integer menuId;

    @JsonAlias({"optiongroupname", "addongroupname"})
    private String optiongroupname;

    @JsonProperty("is_required")
    private boolean is_required;

    @JsonProperty("is_multiple_choice")
    private boolean is_multiple_choice;

    @JsonAlias({"options", "details"})
    @Builder.Default
    private List options = new ArrayList<>();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class OptionDetailDTO {

        private Integer optionid;

        private String optionname;

        private double optionprice;
    }
}