package com.it22mjudelivery.springboot_api.v1.dtos;

import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import jakarta.persistence.Column;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class menuDto {
    private Integer menuid; // เปลี่ยนจาก int -> Integer
    private String menuname;
    private String description;
    private String imageurl;
    private Double price;
    private boolean status;
    private String restaurantid;
    private Integer typeMenuId; // เปลี่ยนจาก int -> Integer
}
