package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;


import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.services.RestaurantService;
import lombok.RequiredArgsConstructor;
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

    @PostMapping("/uploadImage")
    public ResponseEntity<?> uploadImageRegister(@RequestParam("image") MultipartFile file) {
        try {
            // สร้างชื่อไฟล์ไม่ซ้ำกัน
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();

            // สร้างโฟลเดอร์ uploads ถ้ายังไม่มี
            Path uploadDir = Paths.get("uploads", "restaurant", "imageRestaurant");
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            // บันทึกไฟล์
            Path savePath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), savePath);

            // return URL กลับไป
            String imageUrl = "http://10.226.43.211:8081/uploads/restaurant/" + fileName;
            return ResponseEntity.ok(Map.of("url", imageUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

@GetMapping("/searchRestaurant")
    public ResponseEntity<List<Restaurant>> searchRestaurant(@RequestParam String name){
        return ResponseEntity.ok(restaurantRepository.findByRestaurantnameContainingIgnoreCaseAndVerificationstatusTrue(name));
}
}
