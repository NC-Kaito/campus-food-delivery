package com.it22mjudelivery.springboot_api.v1.controllers.menu;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.dtos.menuDto;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/menu")
public class MenuController { // แนะนำให้ใช้ M ตัวใหญ่ตามมาตรฐาน Java นะครับ

    private final MenuService menuService;

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
    public ResponseEntity<?> updateMenuStatus(@RequestBody menuDto dto) {
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




}