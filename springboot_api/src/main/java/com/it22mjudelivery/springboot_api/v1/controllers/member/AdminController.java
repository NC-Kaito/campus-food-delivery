package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.AdminDto;
import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RiderRepository;
import com.it22mjudelivery.springboot_api.v1.services.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/admin")
public class AdminController {
    private final AdminService adminService;
    private final RestaurantRepository restaurantRepository;
    private final RiderRepository riderRepository;

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

    // DashboardController.java
    @GetMapping("/count")
    public ResponseEntity<?> getDashboardCount() {
        long totalRestaurant = restaurantRepository.countByVerificationstatus("true");
        long newRestaurant   = restaurantRepository.countByVerificationstatus("wait");
        long totalRider      = riderRepository.countByVerificationStatus("true");
        long newRider        = riderRepository.countByVerificationStatus("wait");

        return ResponseEntity.ok(Map.of(
                "totalRestaurant", totalRestaurant,
                "newRestaurant",   newRestaurant,
                "totalRider",      totalRider,
                "newRider",        newRider
        ));
    }

    //--------------------------------------------------------------------------------------------------
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

    //----------Rider-------------------------------------------------------------------------------------

    @GetMapping("/list_register_rider")
    public List<Rider> getList_register_rider() {return adminService.getList_register_rider();}


    @GetMapping("/getRiderById/{id}") // เพิ่ม /{id} ต่อท้าย URL
    public ResponseEntity<?> getRiderById(@PathVariable String id) { // รับค่า id เข้ามา
        try {
            Rider rider = adminService.getRiderById(id); // ส่ง id ไปให้ service
            return ResponseEntity.ok(rider);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("ไม่พบข้อมูลร้านอาหาร");
        }
    }

    @PostMapping("/approveRider/{studentid}")
    public ResponseEntity<?> approveRider(@PathVariable String studentid) {
        try {
            adminService.approveRider(studentid);
            return ResponseEntity.ok("อนุมัติร้านค้าสำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการอนุมัติ");
        }
    }


    @PostMapping("/rejectRider/{studentid}")
    public ResponseEntity<?> rejectRider(
            @PathVariable String studentid,
            @RequestParam String reason) { // รับเหตุผลผ่าน Query Parameter หรือใช้ Body ก็ได้
        try {
            adminService.rejectRider(studentid, reason);
            return ResponseEntity.ok("ปฏิเสธผู้จัดส่งสำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการปฏิเสธ");
        }
    }



}
