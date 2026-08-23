package com.it22mjudelivery.springboot_api.v1.controllers.rider;

import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.services.RiderService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/rider")
public class RiderController {
    private final RiderService riderService;

    // 🎯 ดึงค่า URL และ Key ของ Supabase จาก application.properties
    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

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

            Thread.sleep(500); // ⏱️ พัก 0.5 วินาทีให้ Supabase หายใจ

            // ✅ อัปโหลดรูปที่ 2
            String vehicleImagePath = saveFile(vehicleFile, "vehicleImage");

            Thread.sleep(500); // ⏱️ พัก 0.5 วินาที

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

    // 🎯 เปลี่ยนไส้ในฟังก์ชันนี้ให้ยิงไฟล์ขึ้น Supabase Storage
    private String saveFile(MultipartFile file, String subFolder) throws IOException {
        if (file == null || file.isEmpty()) return null;

        String originalFilename = file.getOriginalFilename() != null
                ? file.getOriginalFilename()
                : "file";
        String safeFilename = originalFilename.replaceAll("\\s+", "");
        String fileName = UUID.randomUUID() + "_" + safeFilename;

        // 🎯 กำหนด Bucket Name (ตั้งชื่อให้สอดคล้องกับของร้านค้า)
        String bucketName = "campus-food-delivery-images-rider";
        String filePath = "rider/" + subFolder + "/" + fileName;

        // 🎯 ยิง API ไปที่ Supabase
        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(supabaseKey);

        // กันเหนียวกรณีที่ contentType เป็น null ให้ตั้งค่าเป็นภาพ jpeg พื้นฐาน
        String contentType = file.getContentType();
        if (contentType == null) contentType = "image/jpeg";
        headers.setContentType(MediaType.parseMediaType(contentType));

        HttpEntity<byte[]> requestEntity = new HttpEntity<>(file.getBytes(), headers);
        String uploadUrl = supabaseUrl + "/storage/v1/object/" + bucketName + "/" + filePath;

        ResponseEntity<String> response = restTemplate.exchange(
                uploadUrl,
                HttpMethod.POST,
                requestEntity,
                String.class
        );

        if (response.getStatusCode().is2xxSuccessful()) {
            String publicUrl = supabaseUrl + "/storage/v1/object/public/" + bucketName + "/" + filePath;

            System.out.println("✅ Upload Rider Image Success: [" + subFolder + "]");
            System.out.println("📌 URL: " + publicUrl);

            return publicUrl;
        } else {
            throw new IOException("อัปโหลดรูปภาพประเภท " + subFolder + " ไป Supabase ไม่สำเร็จ");
        }
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