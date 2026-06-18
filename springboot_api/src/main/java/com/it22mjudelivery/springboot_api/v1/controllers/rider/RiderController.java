package com.it22mjudelivery.springboot_api.v1.controllers.rider;

import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Order;
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
import java.util.List;
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

        Path uploadDir = Paths.get("uploads", "rider", subFolder);

        if (!Files.exists(uploadDir)) {
            Files.createDirectories(uploadDir);
        }

        Path savePath = uploadDir.resolve(fileName);
        Files.copy(file.getInputStream(), savePath);

        return "uploads/rider/" + subFolder + "/" + fileName;
    }

    @GetMapping("/getRider")
    public ResponseEntity<?> getRiderByStudentId(@RequestParam("studentId") String studentId) {
        try {
            RiderDto rider = riderService.getRiderByStudentId(studentId);
            return ResponseEntity.ok(rider);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "status", "error",
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/updateIsActive")
// 🎯 แก้หัวเมธอดตรงนี้: เปลี่ยนจาก @RequestParam ทั้งหมด ให้เป็น @RequestBody Map แบบนี้ครับ
    public ResponseEntity<?> updateRiderStatus(@RequestBody Map<String, Object> payload) {
        try {
            // 📦 แกะข้อมูลจาก JSON Body ที่ Flutter ส่งมาให้อย่างถูกต้อง
            String studentId = payload.get("studentId").toString();
            boolean isActive = (boolean) payload.get("isActive");

            // ยิงเข้าสู่ชั้น Service ของคุณ Kaito
            boolean isResult = riderService.updateRiderStatus(studentId, isActive);

            if (isResult) {
                return ResponseEntity.ok(Map.of(
                        "status", "success",
                        "message", "เปลี่ยนสถานะการรับงานสำเร็จแล้ว!"
                ));
            }

            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาดภายในระบบ ไม่สามารถเปลี่ยนสถานะได้"
            ));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "status", "error",
                    "message", " เกิดข้อผิดพลาดที่ Rider Controller: " + e.getMessage()
            ));
        }
    }


}
