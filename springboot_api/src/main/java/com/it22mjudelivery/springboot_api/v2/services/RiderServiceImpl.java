package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v2.entities.Major;
import com.it22mjudelivery.springboot_api.v2.entities.Rider;
import com.it22mjudelivery.springboot_api.v2.repositories.MajorRepository;
import com.it22mjudelivery.springboot_api.v2.repositories.RiderRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class RiderServiceImpl implements RiderService {

    private final RiderRepository riderRepository;
    private final MajorRepository majorRepository;

    @Override
    public Rider doLoginRider(String studentId, String password) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"));

        if (!rider.getPassword().equals(password)) {
            throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
        }
        return rider;
    }

    @Override
    public boolean doRegisterRider(RiderDto riderDto) {
        // 1. ตรวจสอบข้อมูลซ้ำ
        if (riderRepository.existsByStudentid(riderDto.getStudentid())) {
            throw new RuntimeException("รหัสนักศึกษานี้ถูกใช้งานไปแล้ว");
        }
        if (riderRepository.existsByEmail(riderDto.getEmail())) {
            throw new RuntimeException("อีเมลนี้ถูกใช้งานไปแล้ว");
        }

        // 2. ดึงข้อมูล Major (สาขา) จาก ID ที่ส่งมาจาก Flutter
        Major major = majorRepository.findById(riderDto.getMajorId())
                .orElseThrow(() -> new RuntimeException("ไม่พบรหัสสาขาที่ระบุ"));

        // 3. แปลงจาก DTO เป็น Entity (ใช้ Builder ของคลาส Rider)
        Rider toSaveRider = Rider.builder()
                .studentid(riderDto.getStudentid())
                .password(riderDto.getPassword())
                .firstName(riderDto.getFirstName())
                .lastName(riderDto.getLastName())
                .birthday(riderDto.getBirthday())
                .email(riderDto.getEmail())
                .phone(riderDto.getPhone())
                .profileRiderImage("") // 🎯 เริ่มต้นเป็นค่าว่าง
                .studentCard_Image(riderDto.getStudentCard_Image())
                .drivingLicenseImg(riderDto.getDrivingLicenseImg())
                .vehiclePlate(riderDto.getVehiclePlate())
                .vehicle_Image(riderDto.getVehicle_Image())
                .major(major)
                .isActive(false)
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now())
                .build();

        // 4. บันทึกลงฐานข้อมูล
        riderRepository.save(toSaveRider);
        return true;
    }

    @Override
    @Transactional
    public RiderDto getRiderByStudentId(String studentId) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้จัดส่งรหัสนักศึกษา: " + studentId));

        return RiderDto.builder()
                .studentid(rider.getStudentid())
                .firstName(rider.getFirstName())
                .lastName(rider.getLastName())
                .birthday(rider.getBirthday())
                .email(rider.getEmail())
                .phone(rider.getPhone())
                .profileRiderImage(rider.getProfileRiderImage()) // 🎯 แมปรูปโปรไฟล์ส่งไปให้ Flutter
                .studentCard_Image(rider.getStudentCard_Image()) // 🎯 รูปบัตรนักศึกษา
                .drivingLicenseImg(rider.getDrivingLicenseImg())
                .vehiclePlate(rider.getVehiclePlate())
                .vehicle_Image(rider.getVehicle_Image())
                .isActive(rider.getIsActive())
                .verificationStatus(rider.getVerificationStatus())
                .registerDate(LocalDate.from(rider.getRegisterDate()))
                .notApproveDetail(rider.getNotApproveDetail())
                .majorId(rider.getMajor() != null ? rider.getMajor().getMajorid() : null)
                .majorName(rider.getMajor() != null ? rider.getMajor().getMajorname() : "ไม่ระบุสาขา")
                .facultyName(rider.getMajor() != null && rider.getMajor().getFaculty() != null
                        ? rider.getMajor().getFaculty().getFacultyname()
                        : "ไม่ระบุคณะ")
                .build();
    }

    @Override
    public boolean updateRiderStatus(String studentId, boolean isActive) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        rider.setIsActive(isActive);
        try {
            riderRepository.save(rider);
        } catch (Exception e) {
            throw new RuntimeException("เกิดข้อผิดพลาดไม่สามารถเปลี่ยนสถานะได้");
        }
        return true;
    }

    // 🎯 เมธอดแก้ไขโปรไฟล์ไรเดอร์ (อัปเดต Phone, Email, ProfileImage)
    @Override
    public boolean updateProfileRider(String studentId, String phone, String profileImage) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบผู้ใช้งานรหัสนักศึกษา: " + studentId));

        if (phone != null && !phone.trim().isEmpty()) {
            rider.setPhone(phone.trim());
        }

        // 🎯 แก้ไขชื่อ setter ให้ตรงกับ entity
        if (profileImage != null && !profileImage.trim().isEmpty()) {
            rider.setProfileRiderImage(profileImage.trim());
        }

        try {
            riderRepository.save(rider);
            return true;
        } catch (Exception e) {
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูลโปรไฟล์: " + e.getMessage());
        }
    }
}