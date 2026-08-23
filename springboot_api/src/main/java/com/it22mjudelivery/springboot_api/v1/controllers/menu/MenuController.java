package com.it22mjudelivery.springboot_api.v1.controllers.menu;

import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/menu")
public class MenuController {

    private final MenuService menuService;

    // 🎯 ดึงค่า URL และ Key ของ Supabase จาก application.properties
    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

    @GetMapping("/restaurant/{username}")
    public ResponseEntity<List<Menu>> getMenusByRestaurant(@PathVariable String username) {
        return ResponseEntity.ok(menuService.getMenusByRestaurant(username));
    }

    @GetMapping("/restaurant/{username}/type/{typeMenuId}")
    public ResponseEntity<List<Menu>> getMenusByType(
            @PathVariable String username,
            @PathVariable Integer typeMenuId
    ) {
        return ResponseEntity.ok(menuService.getMenusByRestaurantAndTypeMenu(username, typeMenuId));
    }

    @PostMapping("/updateStatus")
    public ResponseEntity<?> updateMenuStatus(@RequestBody MenuDto dto) {
        try {
            boolean isResult = menuService.updateMenuStatus(dto.getMenuid(), dto.isStatus());
            if (isResult) {
                return ResponseEntity.ok("อัปเดตสถานะเมนูสำเร็จ");
            }
            return ResponseEntity.badRequest().body("ไม่สามารถอัปเดตสถานะได้ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/addMenu")
    public ResponseEntity<?> addMenu(@RequestBody MenuDto requestData) {
        try {
            menuService.saveMenu(requestData);

            return ResponseEntity.ok(Map.of("message", "บันทึกข้อมูลเมนูอาหารสำเร็จ"));

        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(Map.of("message", "เกิดข้อผิดพลาดที่ระบบ: " + e.getMessage()));
        }
    }

    @PostMapping("/updateMenuByRestaurant")
    public ResponseEntity<?> updateMenuByRestaurant(@RequestBody Map<String, Object> requestData) {
        try {
            boolean isSuccess = menuService.updateMenuByRestaurant(requestData);
            if (isSuccess) {
                return ResponseEntity.ok("บันทึกข้อมูลเมนูอาหารและตัวเลือกเสริมสำเร็จ");
            }
            return ResponseEntity.badRequest().body("ไม่สามารถบันทึกข้อมูลได้ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบส่วนกลาง");
        }
    }

    // 🎯 เปลี่ยนแปลงฟังก์ชันให้อัปโหลดภาพเมนูอาหารไปที่ Supabase
    @PostMapping("/uploadMenuImage")
    public ResponseEntity<?> uploadMenuImage(@RequestParam("image") MultipartFile file) {
        try {
            String safeFilename = file.getOriginalFilename().replaceAll("\\s+", "");
            String fileName = UUID.randomUUID() + "_" + safeFilename;

            // 🎯 กำหนด Path ใน Supabase (ใช้ Bucket เดิม แต่แยกเก็บเข้าโฟลเดอร์ menu)
            String bucketName = "campus-food-delivery-images-restaurant";
            String filePath = "menu/" + fileName;

            // 🎯 เตรียม Header เพื่อยิง API ไปที่ Supabase
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(supabaseKey);
            headers.setContentType(MediaType.parseMediaType(file.getContentType()));

            // 🎯 โยนไฟล์เข้าไปใน Body และยิง Request
            HttpEntity<byte[]> requestEntity = new HttpEntity<>(file.getBytes(), headers);
            String uploadUrl = supabaseUrl + "/storage/v1/object/" + bucketName + "/" + filePath;

            ResponseEntity<String> response = restTemplate.exchange(
                    uploadUrl,
                    HttpMethod.POST,
                    requestEntity,
                    String.class
            );

            // 🎯 ถ้ายิงผ่าน ให้ส่ง Public URL กลับไปที่ Flutter
            if (response.getStatusCode().is2xxSuccessful()) {
                String publicUrl = supabaseUrl + "/storage/v1/object/public/" + bucketName + "/" + filePath;

                System.out.println("=========================================");
                System.out.println("✅ Upload Menu Image Success!");
                System.out.println("📌 URL: " + publicUrl);
                System.out.println("=========================================");

                return ResponseEntity.ok(Map.of("url", publicUrl));
            } else {
                return ResponseEntity.badRequest().body("อัปโหลดรูปภาพเมนูไป Supabase ไม่สำเร็จ");
            }

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

    @PostMapping("/deleteMenu")
    public ResponseEntity<?> deleteMenu(@RequestBody Map<String, Object> body) {
        try {
            Object rawId = body.get("menuid");
            if (rawId == null) {
                return ResponseEntity.badRequest().body("กรุณาระบุ menuid");
            }
            int menuId = Integer.parseInt(rawId.toString());

            boolean isResult = menuService.deleteMenu(menuId);
            if (isResult) {
                return ResponseEntity.ok("ลบเมนูสำเร็จ");
            }
            return ResponseEntity.badRequest().body("ไม่พบเมนูที่ต้องการลบ");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }
}