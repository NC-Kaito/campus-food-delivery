package com.it22mjudelivery.springboot_api.v1.controllers.menu;

import com.it22mjudelivery.springboot_api.v1.entities.Menuaddondetail;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddondetailRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddongroupRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/menuAddon")
@CrossOrigin(origins = "*") // อนุญาตให้ Flutter ยิงข้ามโดเมนเข้ามาได้
public class MenuAddonController {

    @Autowired
    private MenuaddongroupRepository menuaddongroupRepository;

    @GetMapping("/{menuId}/addons")
    public ResponseEntity<?> getMenuAddons(@PathVariable Long menuId) {
        // ดึงข้อมูลลูกผสมทุกตารางออกมารวดเดียว
        List<Menuaddongroup> groups = menuaddongroupRepository.findByMenu_Menuid(menuId);

        // 🎯 3. พ่นก้อนโครงสร้างต้นไม้ส่งคืนไปให้ Flutter แตกยอดแยกหมวดหมู่ UI ได้เลย
        return ResponseEntity.ok(groups);
    }
}
