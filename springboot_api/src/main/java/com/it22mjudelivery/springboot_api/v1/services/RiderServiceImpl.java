package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.MajorRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RiderRepository;
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

        // ⚠️ ในอนาคตอย่าลืมใช้ PasswordEncoder นะเพื่อน ตอนนี้เอาแบบ equals ไปก่อน
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
                .password(riderDto.getPassword()) // รับมาจาก DTO
                .firstName(riderDto.getFirstName())
                .lastName(riderDto.getLastName())
                .birthday(riderDto.getBirthday())
                .email(riderDto.getEmail())
                .phone(riderDto.getPhone())
                .studentCard_Image(riderDto.getStudentCard_Image())
                .drivingLicenseImg(riderDto.getDrivingLicenseImg())
                .vehiclePlate(riderDto.getVehiclePlate())
                .vehicle_Image(riderDto.getVehicle_Image())
                .major(major) // ผูกความสัมพันธ์กับ Major
                .isActive(false) // เริ่มต้นให้เป็น false รอการตรวจสอบ
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now()) // บันทึกวันที่สมัครทันที
                .build();

        // 4. บันทึกลงฐานข้อมูล
        riderRepository.save(toSaveRider);
        return true;
    }

    @Override
    @Transactional
    public RiderDto getRiderByStudentId(String studentId) { // 🎯 1. เปลี่ยน Type เป็น RiderDto
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้จัดส่งรหัสนักศึกษา: " + studentId));

        // 🔄 แปลง Entity -> DTO เพื่อส่งข้อมูลไปให้ Flutter วาดหน้าจอ
        return RiderDto.builder() // 🎯 2. ต้องเรียกใช้ RiderDto.builder() ครับ!
                .studentid(rider.getStudentid())
                .firstName(rider.getFirstName())
                .lastName(rider.getLastName())
                .birthday(rider.getBirthday())
                .email(rider.getEmail())
                .phone(rider.getPhone())
                .studentCard_Image(rider.getStudentCard_Image())
                .drivingLicenseImg(rider.getDrivingLicenseImg())
                .vehiclePlate(rider.getVehiclePlate())
                .vehicle_Image(rider.getVehicle_Image())
                .isActive(rider.getIsActive())
                .verificationStatus(rider.getVerificationStatus())
                // 🎯 ใน RiderDto เราเก็บ registerDate เป็น LocalDate เลยดึงมาใส่ได้ตรงๆ เลยครับ
                .registerDate(LocalDate.from(rider.getRegisterDate()))
                .notApproveDetail(rider.getNotApproveDetail())
                .majorId(rider.getMajor() != null ? rider.getMajor().getMajorid() : null)
                .majorName(rider.getMajor() != null ? rider.getMajor().getMajorname() : "ไม่ระบุสาขา")
                .facultyName(rider.getMajor() != null && rider.getMajor().getFaculty() != null
                        ? rider.getMajor().getFaculty().getFacultyname()
                        : "ไม่ระบุคณะ")  // ← เพิ่มบรรทัดนี้
                .build();
    }

    @Override
    public boolean updateRiderStatus(String studentId, boolean isActive) {
        Rider rider = riderRepository.findByStudentid(studentId).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        rider.setIsActive(isActive);
        try{
            riderRepository.save(rider);
        }catch (Exception e){
            new RuntimeException("เกิดข้อพลาดไม่สามารถเปลี่ยนสถานะได้");
            return false;
        }
        return true;
    }
}