package com.it22mjudelivery.springboot_api.v1.controllers.menu;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/menu")
public class MenuController { // แนะนำให้ใช้ M ตัวใหญ่ตามมาตรฐาน Java นะครับ

    // ✅ ต้องใส่ final เพื่อให้ Spring ฉีด Dependency (Inject) ผ่าน Constructor
    private final MenuService menuService;

    @GetMapping("/restaurant/{username}")
    public ResponseEntity<List<Menu>> getMenusByRestaurant(@PathVariable String username) {
        // ก่อนหน้านี้บรรทัดนี้จะพัง (NPE) เพราะ menuService เป็น null
        return ResponseEntity.ok(menuService.getMenusByRestaurant(username));
    }
}