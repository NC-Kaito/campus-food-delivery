package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;

import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.services.RestaurantService;
// 🎯 Import CloudinaryService เข้ามา (เช็ก Package ให้ตรงกับโปรเจกต์คุณด้วยนะครับ)
import com.it22mjudelivery.springboot_api.v1.services.CloudinaryService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/restaurant")
public class RestaurantController {
    private final RestaurantService restaurantService;
    private final RestaurantRepository restaurantRepository;

    // 🎯 ฉีด CloudinaryService เข้ามาใช้งาน
    private final CloudinaryService cloudinaryService;

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

    // 🎯 แก้ไขฟังก์ชันอัปโหลดรูปให้ส่งไปที่ Cloudinary
    @PostMapping("/uploadImage")
    public ResponseEntity<?> uploadImageRegister(
            @RequestParam("image") MultipartFile file,
            @RequestParam("type") String type) {
        try {
            // 1. ตรวจสอบเงื่อนไขแยกประเภทโฟลเดอร์
            String targetSubFolder = "imageRestaurant";
            if ("ownerImage".equalsIgnoreCase(type)) {
                targetSubFolder = "ownerImage";
            }

            // 2. กำหนดชื่อโฟลเดอร์หลักใน Cloudinary
            String folderName = "maejo_delivery/restaurants/" + targetSubFolder;

            // 3. เรียกใช้ CloudinaryService เพื่ออัปโหลดและรับ URL กลับมา
            String publicUrl = cloudinaryService.uploadImage(file, folderName);

            // 4. พิมพ์ Log เพื่อเช็กความเรียบร้อย
            System.out.println("=========================================");
            System.out.println("✅ Upload to Cloudinary Success!");
            System.out.println("📌 URL: " + publicUrl);
            System.out.println("=========================================");

            // 5. ส่ง URL กลับไปให้ Flutter (Format เดิม Flutter จะได้ไม่ต้องแก้โค้ด)
            return ResponseEntity.ok(Map.of("url", publicUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

    @GetMapping("/searchRestaurant")
    public ResponseEntity<List<Restaurant>> searchRestaurant(@RequestParam String name) {
        List<Restaurant> results = restaurantRepository.searchByStoreOrMenu(name, "true");
        return ResponseEntity.ok(results);
    }

    //------Restaurant---------------------------------------------------------------------
    @GetMapping("/getRestaurantByUsername/{username}")
    public ResponseEntity<?> getRestaurantByUsername(@PathVariable String username) {
        Restaurant rest = restaurantService.getRestaurantByUsername(username);
        if (rest != null) {
            return ResponseEntity.ok(rest);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("ไม่พบข้อมูลร้านค้า");
        }
    }

    @PostMapping("/updateStatusOpen")
    public ResponseEntity<?> updateStatusOpen(@RequestBody RestaurantDto restaurantDto) {
        try {
            boolean isResult = restaurantService.updateStatusOpen(restaurantDto.getUsername(),restaurantDto.getStatusopen());
            if (isResult) {
                return ResponseEntity.ok("updateStatusOpen สำเร็จ");
            }
            return ResponseEntity.badRequest().body("updateStatusOpen ไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/updateProfileRestaurant")
    public ResponseEntity<?> updateProfileRestaurant(@RequestBody RestaurantDto restaurantDto){
        try {
            boolean isResult = restaurantService.updateProfileRestaurant(
                    restaurantDto.getUsername(), restaurantDto.getRestaurantname(), restaurantDto.getRestaurantimage(), restaurantDto.getTypeid(),
                    restaurantDto.getLatitude(), restaurantDto.getLongitude(),
                    restaurantDto.getOpeningHours(),
                    restaurantDto.getOwnerfirstname(),
                    restaurantDto.getOwnerlastname(), restaurantDto.getEmail(), restaurantDto.getPhone(), restaurantDto.getImagecardid());
            if (isResult) {
                return ResponseEntity.ok("updateProfileRestaurant สำเร็จ");
            }
            return ResponseEntity.badRequest().body("updateProfileRestaurant ไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/updateRegisterRestaurant")
    public ResponseEntity<?> updateRegisterRestaurant(@RequestBody RestaurantDto restaurantDto){
        try {
            boolean isResult = restaurantService.updateRegisterRestaurant(
                    restaurantDto.getUsername(), restaurantDto.getRestaurantname(), restaurantDto.getRestaurantimage(), restaurantDto.getTypeid(),
                    restaurantDto.getLatitude(), restaurantDto.getLongitude(),
                    restaurantDto.getOpeningHours(),
                    restaurantDto.getOwnerfirstname(),
                    restaurantDto.getOwnerlastname(), restaurantDto.getEmail(), restaurantDto.getPhone(), restaurantDto.getImagecardid());
            if (isResult) {
                return ResponseEntity.ok("updateProfileRestaurant สำเร็จ");
            }
            return ResponseEntity.badRequest().body("updateProfileRestaurant ไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/doCloseAccount/{username}")
    public ResponseEntity<?> doCloseAccount(@PathVariable String username) {
        try {
            restaurantService.doCloseAccount(username);
            return ResponseEntity.ok("อนุมัติร้านค้าสำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการอนุมัติ");
        }
    }
}