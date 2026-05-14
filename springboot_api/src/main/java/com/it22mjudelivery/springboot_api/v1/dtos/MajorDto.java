package com.it22mjudelivery.springboot_api.v1.dtos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MajorDto {
    private Integer majorId;
    private String majorName;
    private Integer facultyId; // ส่งแค่ ID ไปก็พอ
    private String facultyName; // หรือจะส่งชื่อคณะไปโชว์คู่กันก็ได้
}