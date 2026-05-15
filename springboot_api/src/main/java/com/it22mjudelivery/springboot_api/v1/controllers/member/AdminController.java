package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.AdminDto;
import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.services.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/admin")
public class AdminController {
    private final AdminService adminService;

    @PostMapping("/loginAdmin")
    public ResponseEntity<?> doLoginAdmin(@RequestBody AdminDto adminDio){
        try {
            Admin admin = adminService.doLoginAdmin(adminDio.getUsername(), adminDio.getPassword());
            return ResponseEntity.ok(admin);
        }catch (RuntimeException e){
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }catch (Exception e){
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @GetMapping("/list_register_rest")
    public List<Restaurant> getList_register_rest() {return adminService.getList_register_rest();}


    @GetMapping("/getRestaurantById/{id}") // เพิ่ม /{id} ต่อท้าย URL
    public ResponseEntity<?> getRestaurantById(@PathVariable String id) { // รับค่า id เข้ามา
        try {
            Restaurant restaurant = adminService.getRestaurantById(id); // ส่ง id ไปให้ service
            return ResponseEntity.ok(restaurant);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("ไม่พบข้อมูลร้านอาหาร");
        }
    }

    // =========================================================================
    // APPROVE RESTAURANT
    // =========================================================================
    @PostMapping("/approveRestaurant/{username}")
    public ResponseEntity<?> approveRestaurant(@PathVariable String username) {
        try {
            adminService.approveRestaurant(username);
            return ResponseEntity.ok("อนุมัติร้านค้าสำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการอนุมัติ");
        }
    }

    // =========================================================================
    // REJECT RESTAURANT
    // =========================================================================
    @PostMapping("/rejectRestaurant/{username}")
    public ResponseEntity<?> rejectRestaurant(
            @PathVariable String username,
            @RequestParam String reason) { // รับเหตุผลผ่าน Query Parameter หรือใช้ Body ก็ได้
        try {
            adminService.rejectRestaurant(username, reason);
            return ResponseEntity.ok("ปฏิเสธร้านค้าสำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการปฏิเสธ");
        }
    }


}
