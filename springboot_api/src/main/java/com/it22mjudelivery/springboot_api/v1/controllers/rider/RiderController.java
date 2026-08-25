package com.it22mjudelivery.springboot_api.v1.controllers.rider;

import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.services.RiderService;
// 🎯 Import CloudinaryService เข้ามา
import com.it22mjudelivery.springboot_api.v1.services.CloudinaryService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/rider")
public class RiderController {

    private final RiderService riderService;
    // 🎯 ฉีด CloudinaryService เข้ามาใช้งาน
    private final CloudinaryService cloudinaryService;

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
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    // 🎯 รับไฟล์แล้วเรียก saveFile() ซึ่งทำงานเร็วกว่าเดิม ไม่ต้องใช้ Thread.sleep แล้ว
    @PostMapping("/registerRiderWithImages")
    public ResponseEntity<?> registerRider(
            @RequestPart("studentCardImage") MultipartFile studentCardFile,
            @RequestPart("vehicleImage") MultipartFile vehicleFile,
            @RequestPart("drivingLicenseImg") MultipartFile drivingLicenseFile,
            @RequestPart("riderData") String riderJson
    ) {
        try {
            // ✅ อัปโหลดรูปที่ 1
            String studentCardPath = saveFile(studentCardFile, "studentCard");

            // ✅ อัปโหลดรูปที่ 2
            String vehicleImagePath = saveFile(vehicleFile, "vehicleImage");

            // ✅ อัปโหลดรูปที่ 3
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

    // 🎯 เปลี่ยนไส้ในฟังก์ชันนี้ให้ยิงไฟล์ขึ้น Cloudinary แทน
    private String saveFile(MultipartFile file, String subFolder) {
        if (file == null || file.isEmpty()) return null;

        // 🎯 กำหนด Folder Name สำหรับ Rider โดยเฉพาะ
        String folderName = "maejo_delivery/riders/" + subFolder;

        // 🎯 เรียกใช้ CloudinaryService
        String publicUrl = cloudinaryService.uploadImage(file, folderName);

        System.out.println("✅ Upload Rider Image Success: [" + subFolder + "]");
        System.out.println("📌 URL: " + publicUrl);

        return publicUrl;
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
    public ResponseEntity<?> updateRiderStatus(@RequestBody Map<String, Object> payload) {
        try {
            String studentId = payload.get("studentId").toString();
            boolean isActive = (boolean) payload.get("isActive");

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