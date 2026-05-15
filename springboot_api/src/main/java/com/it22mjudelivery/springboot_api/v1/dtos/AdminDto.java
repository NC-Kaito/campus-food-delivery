package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AdminDto {
    private String username;
    private String password;
    private String firstname;
    private String lastname;
}
