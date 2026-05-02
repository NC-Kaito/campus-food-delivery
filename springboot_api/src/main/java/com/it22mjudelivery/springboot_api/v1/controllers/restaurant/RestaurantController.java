package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;


import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.services.RestaurantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/restaurant")
public class RestaurantController {
    private RestaurantService restaurantService;

    @PostMapping("/registerRestaurant")
    public ResponseEntity<?> doRegisterRestaurant(@RequestBody RestaurantDto restaurantDto) {
        try {
            boolean isResult = restaurantService.doRegisterRestaurant(restaurantDto);
            if (isResult) {
                return ResponseEntity.ok("สมัครร้านค้าเรียบร้อย กรุณาเข้าสุ่ระบบเพื่อดุผลลัพธ์การสมัคร ");
            }
            return ResponseEntity.badRequest().body("สมัครร้านค้าไม่สำเร็จ");
        } catch (RuntimeException e) {
            // จับข้อความที่เรา throw เช่น "ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว"
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            // กรณีเกิด Error อื่นๆ ที่ไม่ได้คาดคิด
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }
}
