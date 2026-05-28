package com.it22mjudelivery.springboot_api.v1.controllers.menu;

import com.it22mjudelivery.springboot_api.v1.entities.Addonmenu;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddondetail;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.repositories.AddonmenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddondetailRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddongroupRepository;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/menuAddon")
@CrossOrigin(origins = "*") // อนุญาตให้ Flutter ยิงข้ามโดเมนเข้ามาได้
public class MenuAddonController {

    @Autowired
    private MenuaddongroupRepository menuaddongroupRepository;

    @Autowired
    private AddonmenuRepository addonmenuRepository;

    @Autowired
    private MenuService menuService;

    @GetMapping("/{menuId}/addons")
    public ResponseEntity<?> getMenuAddons(@PathVariable Long menuId) {
        // ดึงข้อมูลลูกผสมทุกตารางออกมารวดเดียว
        List<Menuaddongroup> groups = menuaddongroupRepository.findByMenu_Menuid(menuId);

        // 🎯 3. พ่นก้อนโครงสร้างต้นไม้ส่งคืนไปให้ Flutter แตกยอดแยกหมวดหมู่ UI ได้เลย
        return ResponseEntity.ok(groups);
    }

    @GetMapping("/addons")
    public ResponseEntity<List<Addonmenu>> getRestaurantAddons(@RequestParam("username") String username) {
        List<Addonmenu> restaurantAddons = addonmenuRepository.findAllByRestaurantUsername(username);
        return ResponseEntity.ok(restaurantAddons);
    }

    // เพิ่มเมธอดนี้ต่อท้ายในคลาส MenuController.java
    @PostMapping("/addMenuWithAddons")
    public ResponseEntity<?> addMenuWithAddons(@RequestBody Map<String, Object> requestData) {
        try {
            boolean isSuccess = menuService.saveMenuWithAddons(requestData);
            if (isSuccess) {
                return ResponseEntity.ok("บันทึกข้อมูลเมนูอาหารและตัวเลือกเสริมสำเร็จ");
            }
            return ResponseEntity.badRequest().body("ไม่สามารถบันทึกข้อมูลได้ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบส่วนกลาง");
        }
    }
}
