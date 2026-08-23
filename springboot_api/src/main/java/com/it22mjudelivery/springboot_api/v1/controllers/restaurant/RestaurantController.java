package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.services.RestaurantService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/restaurant")
public class RestaurantController {
    private final RestaurantService restaurantService;
    private final RestaurantRepository restaurantRepository;

    // 🎯 ดึงค่า URL และ Key จาก application.properties
    @Value("${supabase.url}")
    private String supabaseUrl;

    @Value("${supabase.key}")
    private String supabaseKey;

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

    @PostMapping("/uploadImage")
    public ResponseEntity<?> uploadImageRegister(
            @RequestParam("image") MultipartFile file,
            @RequestParam("type") String type) {
        try {
            String safeFilename = file.getOriginalFilename().replaceAll("\\s+", "");
            String fileName = UUID.randomUUID() + "_" + safeFilename;

            // ตรวจสอบเงื่อนไขแยกประเภทโฟลเดอร์
            String targetSubFolder = "imageRestaurant";
            if ("ownerImage".equalsIgnoreCase(type)) {
                targetSubFolder = "ownerImage";
            }

            // 🎯 กำหนด Path ใน Supabase
            String bucketName = "campus-food-delivery-images-restaurant"; //  Bucket name
            String filePath = "restaurant/" + targetSubFolder + "/" + fileName;

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

                // ---------------------------------------------------------
                // 🔎 เพิ่มคำสั่งตรวจสอบความยาว URL ตรงนี้ครับ
                System.out.println("=========================================");
                System.out.println("✅ Upload Success!");
                System.out.println("📌 URL: " + publicUrl);
                System.out.println("📏 URL Length: " + publicUrl.length() + " characters");
                System.out.println("=========================================");
                // ---------------------------------------------------------

                return ResponseEntity.ok(Map.of("url", publicUrl));
            } else {
                return ResponseEntity.badRequest().body("อัปโหลดรูปภาพไป Supabase ไม่สำเร็จ");
            }

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