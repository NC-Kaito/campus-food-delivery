package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;

import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.services.RestaurantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/restaurant")
public class RestaurantController {
    private final RestaurantService restaurantService;
    private final RestaurantRepository restaurantRepository;

    @PostMapping("/loginRestaurant")
    public ResponseEntity<?> doLoginRestaurant(@RequestBody Map<String, String> loginData) {
        try {
            String username = loginData.get("username");
            String password = loginData.get("password");

            Restaurant restaurant = restaurantService.doLoginRestaurant(username, password);
            return ResponseEntity.ok(restaurant);

        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        } catch (Exception e) {
            System.out.println("Login Error: " + e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/registerRestaurant")
    public ResponseEntity<?> doRegisterRestaurant(@RequestBody RestaurantDto restaurantDto) {
        try {
            boolean isResult = restaurantService.doRegisterRestaurant(restaurantDto);
            if (isResult) {
                return ResponseEntity.ok("สมัครร้านค้าเรียบร้อย");
            }
            return ResponseEntity.badRequest().body("สมัครร้านค้าไม่สำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    // 🎯 เพิ่มเติมฟังก์ชันอัปโหลดภาพอัจฉริยะ รองรับการคัดกรองแยกโฟลเดอร์เก็บข้อมูลจริง
    @PostMapping("/uploadImage")
    public ResponseEntity<?> uploadImageRegister(
            @RequestParam("image") MultipartFile file,
            @RequestParam("type") String type) {
        try {
            String safeFilename = file.getOriginalFilename().replaceAll("\\s+", "");
            String fileName = UUID.randomUUID() + "_" + safeFilename;

            // ตรวจสอบเงื่อนไขแยกประเภทโฟลเดอร์ตามหน้าบ้านส่งคำสั่งมา
            String targetSubFolder = "imageRestaurant";
            if ("lease".equalsIgnoreCase(type)) {
                targetSubFolder = "imgLeaseAgreement";
            }

            Path uploadDir = Paths.get("uploads", "restaurant", targetSubFolder);
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            Path savePath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), savePath);

            // ต่อ String คืนค่า URL ที่มีเครื่องหมาย / คั่นพาร์ทถูกต้องสมบูรณ์กลับไป
            String imageUrl = "http://10.244.27.211:8081/uploads/restaurant/" + targetSubFolder + "/" + fileName;
            return ResponseEntity.ok(Map.of("url", imageUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

    @GetMapping("/searchRestaurant")
    public ResponseEntity<List<Restaurant>> searchRestaurant(@RequestParam String name) {
        return ResponseEntity.ok(restaurantRepository.findByRestaurantnameContainingIgnoreCaseAndVerificationstatusTrue(name));
    }
}