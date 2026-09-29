package com.it22mjudelivery.springboot_api.v1.dtos;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AddOrderDetailOptionDto {

    private int optionId;

    private String optionNameAtOrder;

    private double priceAtOrder;

    private int optionQty = 1;

}