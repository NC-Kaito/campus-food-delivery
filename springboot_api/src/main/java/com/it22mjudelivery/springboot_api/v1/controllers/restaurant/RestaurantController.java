    package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;

    import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
    import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
    import com.it22mjudelivery.springboot_api.v1.entities.Member;
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
                if ("ownerImage".equalsIgnoreCase(type)) {
                    targetSubFolder = "ownerImage";
                }

                Path uploadDir = Paths.get("uploads", "restaurant", targetSubFolder);
                if (!Files.exists(uploadDir)) {
                    Files.createDirectories(uploadDir);
                }

                Path savePath = uploadDir.resolve(fileName);
                Files.copy(file.getInputStream(), savePath);

                String imageUrl = "uploads/restaurant/" + targetSubFolder + "/" + fileName;
                return ResponseEntity.ok(Map.of("url", imageUrl));

            } catch (Exception e) {
                return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
            }
        }

        @GetMapping("/searchRestaurant")
        public ResponseEntity<List<Restaurant>> searchRestaurant(@RequestParam String name) {
            return ResponseEntity.ok(restaurantRepository.findByRestaurantnameContainingIgnoreCaseAndVerificationstatus(name, "true"));
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
                        restaurantDto.getUsername(),restaurantDto.getRestaurantname(),restaurantDto.getRestaurantimage(),restaurantDto.getTypeid(),
                        restaurantDto.getLatitude(),restaurantDto.getLongitude(),
                        restaurantDto.getOpentime(),
                        restaurantDto.getClosetime(),restaurantDto.getOpenday(),restaurantDto.getOwnerfirstname(),
                        restaurantDto.getOwnerlastname(),restaurantDto.getEmail(),restaurantDto.getPhone());
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


    }





