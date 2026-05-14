package com.it22mjudelivery.springboot_api.v1.dtos;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FacultyDto {
    private Integer facultyId;
    private String facultyName;
}