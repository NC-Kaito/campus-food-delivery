package com.it22mjudelivery.springboot_api.v1.controllers.menu;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.dtos.menuDto;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
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

    @PostMapping("/uploadMenuImage")
    public ResponseEntity<?> uploadMenuImage(@RequestParam("image") MultipartFile file) {
        try {
            // สร้างชื่อไฟล์ไม่ซ้ำกัน
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();

            // 🎯 จุดที่ 1: ตรวจเช็คให้มั่นใจว่าพิกัดโฟลเดอร์เก็บไฟล์จริงเอาไว้ที่ไหน
            // แนะนำให้ยิงตรงเข้าโฟลเดอร์ member/ เพื่อความง่ายและสั้นในการจัดพาร์ทครับ
            Path uploadDir = Paths.get("uploads", "restaurant", "menu");
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            // บันทึกไฟล์ลงเซิร์ฟเวอร์จริง
            Path savePath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), savePath);

            // 🎯 จุดที่ 2: เปลี่ยนมาส่งโครงสร้าง URL แบบเต็มสาย ชี้เข้าพาร์ทโฟลเดอร์เสมือน (Static Resource) ให้ตรงกับที่บันทึกจริง
            // เติมเครื่องหมาย / คั่นท้ายโฟลเดอร์ member/ ให้ถูกต้องด้วยครับ
            String imageUrl = "http://10.244.27.211:8081/uploads/restaurant/menu/" + fileName;

            return ResponseEntity.ok(Map.of("url", imageUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }


}