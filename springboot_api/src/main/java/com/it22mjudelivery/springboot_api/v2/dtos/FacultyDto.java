package com.it22mjudelivery.springboot_api.v2.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FacultyDto {
    private Integer facultyId;
    private String facultyName;
}