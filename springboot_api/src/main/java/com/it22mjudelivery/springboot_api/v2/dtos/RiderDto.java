package com.it22mjudelivery.springboot_api.v2.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RiderDto {
    private String studentid;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String password;

    private String firstName;
    private String lastName;
    private LocalDate birthday;
    private String email;
    private String phone;
    private String profileRiderImage;
    private String studentCard_Image;
    private String drivingLicenseImg;
    private String vehiclePlate;
    private String vehicle_Image;
    private Boolean isActive;
    private String verificationStatus;
    private LocalDate registerDate;
    private String notApproveDetail;

    // สำหรับรับค่า ID จากหน้าบ้านตอน Register
    private Integer majorId;

    // สำหรับส่งชื่อสาขาไปโชว์ที่หน้าบ้านตอน Get ข้อมูล
    private String majorName;

    private String facultyName;
}