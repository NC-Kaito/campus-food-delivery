package com.it22mjudelivery.springboot_api.v1.dtos;

import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TypeMenuDto {
    private int typemenuId;
    private String typemenuName;
}
