package com.it22mjudelivery.springboot_api.v1.controllers.rider;

import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.services.RiderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/rider")
public class RiderController {
    private final RiderService riderService;

    @PostMapping("/loginRider")
    public ResponseEntity<?> doLoginRider(@RequestBody RiderDto riderDto){
        try {
            Rider rider = riderService.doLoginRider(riderDto.getStudentid(), riderDto.getPassword());
            return ResponseEntity.ok(rider);
        }catch (RuntimeException e){
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }catch (Exception e){
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/registerRider")
    public ResponseEntity<?> doRegisterRider(@RequestBody RiderDto riderDto) {
        try {
            boolean isResult = riderService.doRegisterRider(riderDto);
            if (isResult) {
                return ResponseEntity.ok("สมัครผู้จัดส่งสำเร็จ");
            }
            return ResponseEntity.badRequest().body("สมัครผู้จัดส่งไม่สำเร็จ");
        } catch (RuntimeException e) {
            // จับข้อความที่เรา throw เช่น "ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว"
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            // กรณีเกิด Error อื่นๆ ที่ไม่ได้คาดคิด
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/registerRiderWithImages")
    public ResponseEntity<?> registerRider(
            @RequestPart("studentCardImage") MultipartFile studentCardFile,
            @RequestPart("vehicleImage") MultipartFile vehicleFile,
            @RequestPart("drivingLicenseImg") MultipartFile drivingLicenseFile,
            @RequestPart("riderData") String riderJson // หรือรับเป็น @ModelAttribute DTO ก็ได้
    ) {
        try {
            // ✅ เรียกใช้ฟังก์ชันเดียว แต่แยกโฟลเดอร์ปลายทาง
            String studentCardPath = saveFile(studentCardFile, "studentCard");
            String vehicleImagePath = saveFile(vehicleFile, "vehicleImage");
            String drivingLicensePath = saveFile(drivingLicenseFile, "drivingLicenseImg");

            // ตรงนี้เพื่อนก็เอา studentCardPath และ vehicleImagePath
            // ไป save ลง Database ใน Table Rider ได้เลยครับ

            Map<String, String> response = new HashMap<>();
            response.put("studentCardUrl", studentCardPath);
            response.put("vehicleImageUrl", vehicleImagePath);
            response.put("drivingLicenseUrl", drivingLicensePath);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("สมัครสมาชิกไม่สำเร็จ: " + e.getMessage());
        }
    }

    private String saveFile(MultipartFile file, String subFolder) throws IOException {
        if (file.isEmpty()) return null;

        String originalFilename = file.getOriginalFilename() != null
                ? file.getOriginalFilename()
                : "file";
        String safeFilename = originalFilename.replaceAll("\\s+", "");
        String fileName = UUID.randomUUID() + "_" + safeFilename;

        // 2. กำหนด Path (เช่น uploads/rider/studentCard)
        Path uploadDir = Paths.get("uploads", "rider", subFolder);

        // 3. สร้างโฟลเดอร์ถ้ายังไม่มี
        if (!Files.exists(uploadDir)) {
            Files.createDirectories(uploadDir);
        }

        // 4. บันทึกไฟล์
        Path savePath = uploadDir.resolve(fileName);
        Files.copy(file.getInputStream(), savePath);

        // 5. คืนค่า Path เพื่อเอาไปเก็บลง Database (เช่น rider/studentCard/filename.jpg)
        return "rider/" + subFolder + "/" + fileName;
    }
}
