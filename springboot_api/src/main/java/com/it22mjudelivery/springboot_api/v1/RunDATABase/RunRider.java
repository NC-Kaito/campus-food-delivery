package com.it22mjudelivery.springboot_api.v1.RunDATABase;

import com.it22mjudelivery.springboot_api.SpringbootApiApplication;
import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.MajorRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RiderRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

public class RunRider {
    public static void main(String[] args) {
        ApplicationContext context = SpringApplication.run(SpringbootApiApplication.class, args);

        MajorRepository majorRepository = context.getBean(MajorRepository.class);
        RiderRepository riderRepository = context.getBean(RiderRepository.class);

        // =========================================================================
        // STEP 1: ดึงข้อมูล Major ที่มีอยู่แล้วจาก Database (สมมติว่าเป็น ID ของสาขา IT คือ 1)
        // =========================================================================
        // ใช้ .orElseThrow เพื่อให้ระบบแจ้งเตือนชัดเจนถ้าหากหา ID: 1 ใน DB ไม่เจอจริงๆ
        Major existingMajor = majorRepository.findById(1)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลสาขาวิชา ID: 1 ในฐานข้อมูล กรุณาตรวจสอบอีกครั้ง"));

        // =========================================================================
        // STEP 2: สร้างข้อมูล Rider 5 คน โดยผูกกับ existingMajor ที่ดึงมา
        // =========================================================================
        Rider rider1 = Rider.builder()
                .studentid("6604101301")
                .password("password123")
                .firstName("สมชาย")
                .lastName("สายซิ่ง")
                .birthday(LocalDate.of(2004, 5, 15))
                .email("somchai66@mju.ac.th")
                .phone("0812345678")
                .studentCard_Image("card_somchai.png")
                .drivingLicenseImg("license_somchai.png")
                .vehiclePlate("กข 123 เชียงใหม่")
                .vehicle_Image("wave110_red.png")
                .isActive(true)
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now())
                .major(existingMajor) // ✨ ส่ง Object ของ Major เข้าไปแทนตัวเลข
                .build();

        Rider rider2 = Rider.builder()
                .studentid("6604101302")
                .password("password456")
                .firstName("สมหญิง")
                .lastName("ใจดี")
                .birthday(LocalDate.of(2004, 8, 22))
                .email("somying66@mju.ac.th")
                .phone("0823456789")
                .studentCard_Image("card_somying.png")
                .drivingLicenseImg("license_somying.png")
                .vehiclePlate("งจ 999 เชียงใหม่")
                .vehicle_Image("scoopy_white.png")
                .isActive(true)
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now())
                .major(existingMajor) // ✨ เปลี่ยนเป็น existingMajor ทั้งหมด
                .build();

        Rider rider3 = Rider.builder()
                .studentid("6604101303")
                .password("pass789")
                .firstName("กิตติศักดิ์")
                .lastName("พร้อมส่ง")
                .birthday(LocalDate.of(2003, 12, 1))
                .email("kittisak66@mju.ac.th")
                .phone("0834567890")
                .studentCard_Image("card_kitti.png")
                .drivingLicenseImg("license_kitti.png")
                .vehiclePlate("คข 456 ลำพูน")
                .vehicle_Image("pcx_black.png")
                .isActive(true)
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now())
                .major(existingMajor)
                .build();

        Rider rider4 = Rider.builder()
                .studentid("6604101304")
                .password("rider104")
                .firstName("ธนพล")
                .lastName("เรียนดี")
                .birthday(LocalDate.of(2005, 1, 30))
                .email("thanapon66@mju.ac.th")
                .phone("0845678901")
                .studentCard_Image("card_thanapon.png")
                .drivingLicenseImg("license_thanapon.png")
                .vehiclePlate("มจร 789 เชียงใหม่")
                .vehicle_Image("click160_grey.png")
                .isActive(false)
                .verificationStatus("wait")
                .notApproveDetail("ภาพถ่ายใบขับขี่ไม่ชัดเจน กรุณาอัปโหลดใหม่")
                .registerDate(LocalDateTime.now())
                .major(existingMajor)
                .build();

        Rider rider5 = Rider.builder()
                .studentid("6604101305")
                .password("mju2026")
                .firstName("นภา")
                .lastName("ประกายดาว")
                .birthday(LocalDate.of(2004, 3, 18))
                .email("napa66@mju.ac.th")
                .phone("0856789012")
                .studentCard_Image("card_napa.png")
                .drivingLicenseImg("license_napa.png")
                .vehiclePlate("รฟ 555 เชียงราย")
                .vehicle_Image("fazzio_blue.png")
                .isActive(true)
                .verificationStatus("wait")
                .registerDate(LocalDateTime.now())
                .major(existingMajor)
                .build();

        // รวมกลุ่มและเซฟกลุ่ม Rider ลง Database
        List<Rider> riders = Arrays.asList(rider1, rider2, rider3, rider4, rider5);
        riderRepository.saveAll(riders);

        System.out.println("====== Inserted 5 Riders linked to existing Major successfully! ======");
    }
}