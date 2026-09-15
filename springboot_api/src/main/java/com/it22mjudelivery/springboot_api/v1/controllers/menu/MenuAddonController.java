package com.it22mjudelivery.springboot_api.v1.controllers.menu;

import com.it22mjudelivery.springboot_api.v1.dtos.AddonGroupRequestDTO;
import com.it22mjudelivery.springboot_api.v1.entities.Addonmenu;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddondetail;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.repositories.AddonmenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddondetailRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddongroupRepository;
import com.it22mjudelivery.springboot_api.v1.services.AddonService;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
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

    @Autowired
    private AddonService addonService;

    @GetMapping("/{menuId}/addons")
    public ResponseEntity<?> getMenuAddons(@PathVariable Integer menuId) {
        // ดึงข้อมูลลูกผสมทุกตารางออกมารวดเดียว
        List<Menuaddongroup> groups = menuaddongroupRepository.findGroupsByMenuId(menuId);

        // 🎯 3. พ่นก้อนโครงสร้างต้นไม้ส่งคืนไปให้ Flutter แตกยอดแยกหมวดหมู่ UI ได้เลย
        return ResponseEntity.ok(groups);
    }

    @GetMapping("/addons")
    public ResponseEntity<List<Addonmenu>> getRestaurantAddons(@RequestParam("username") String username) {
        List<Addonmenu> restaurantAddons = addonmenuRepository.findAllByRestaurantUsername(username);
        return ResponseEntity.ok(restaurantAddons);
    }





    @PostMapping("/createGroup")
    public ResponseEntity<?> createAddonGroup(@RequestBody AddonGroupRequestDTO request) {
        Map<String, Object> response = new HashMap<>();
        try {
            boolean isSuccess = addonService.createAddonGroupTemplate(request);
            if (isSuccess) {
                response.put("status", "success");
                response.put("message", "สร้างกลุ่มตัวเลือกเสริมเรียบร้อยแล้ว");
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                response.put("status", "error");
                response.put("message", "ไม่สามารถสร้างกลุ่มตัวเลือกเสริมได้");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (Exception e) {
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/updateGroup")
    public ResponseEntity<?> updateAddonGroup(@RequestBody AddonGroupRequestDTO request) {
        Map<String, Object> response = new HashMap<>();
        try {
            boolean isSuccess = addonService.updateAddonGroupTemplate(request);
            if (isSuccess) {
                response.put("status", "success");
                response.put("message", "แก้ไขกลุ่มตัวเลือกเสริมเรียบร้อยแล้ว");
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                response.put("status", "error");
                response.put("message", "ไม่สามารถแก้ไขกลุ่มตัวเลือกเสริมได้");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (Exception e) {
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @Autowired
    private MenuaddondetailRepository menuaddondetailRepository;

    // toggle status ของรายการช้อยส์ย่อย (Menuaddondetail)
    @PatchMapping("/details/{addonDetailId}/status")
    public ResponseEntity<?> toggleDetailStatus(
            @PathVariable Integer addonDetailId,
            @RequestBody Map<String, Boolean> body) {
        return menuaddondetailRepository.findById(addonDetailId)
                .map(detail -> {
                    detail.setStatus(body.get("status"));
                    menuaddondetailRepository.save(detail);
                    return ResponseEntity.ok("อัปเดตสถานะรายการย่อยสำเร็จ");
                }).orElse(ResponseEntity.notFound().build());
    }


    @GetMapping("/searchAddonName")
    public ResponseEntity<?> searchAddonName(@RequestParam String keyword) {
        try {
            List<Addonmenu> results = addonService.searchAddonByName(keyword);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }


    //=====================================================================
    // 🎯 รับ Request จาก Flutter เพื่ออัปเดตสถานะ "ใช้" / "เลิกใช้"
    @PostMapping("/updateMenuMapping")
    public ResponseEntity<?> updateMenuMapping(@RequestBody Map<String, Object> requestData) {
        Map<String, Object> response = new HashMap<>();
        try {
            // ดึงค่ามาจาก JSON ที่ Flutter ส่งมาให้
            Integer menuId = (Integer) requestData.get("menuId");
            List<Integer> addonGroupIds = (List<Integer>) requestData.get("addonGroupIds");

            boolean isSuccess = menuService.updateMenuMapping(menuId, addonGroupIds);

            if (isSuccess) {
                response.put("status", "success");
                response.put("message", "อัปเดตการเชื่อมโยงตัวเลือกเสริมสำเร็จ");
                return ResponseEntity.ok(response);
            } else {
                response.put("status", "error");
                response.put("message", "ไม่สามารถบันทึกข้อมูลได้");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (RuntimeException e) {
            e.printStackTrace(); // ← เพิ่มไว้ดู stack trace จริงตอน debug (ลบออกทีหลังได้)
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } catch (Exception e) {
            e.printStackTrace();
            response.put("status", "error");
            response.put("message", "เกิดข้อผิดพลาดที่ระบบส่วนกลาง: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/groups/{groupId}")
    public ResponseEntity deleteAddonGroup(@PathVariable Integer groupId) {
        Map response = new HashMap<>(); // สร้าง Map สำหรับเป็น JSON
        try {
            boolean isSuccess = addonService.deleteAddonGroup(groupId);
            if (isSuccess) {
                response.put("message", "ลบตัวเลือกเสริมสำเร็จ");
                return ResponseEntity.ok(response);
            }
            response.put("message", "ไม่สามารถลบตัวเลือกเสริมได้");
            return ResponseEntity.badRequest().body(response);
        } catch (RuntimeException e) {
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response); // ส่ง JSON กลับไป
        } catch (Exception e) {
            response.put("message", "เกิดข้อผิดพลาดที่ระบบ");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/groups")
    public ResponseEntity<?> getGroupsByUsername(@RequestParam("username") String username) {
        try {
            List<Menuaddongroup> groups = menuaddongroupRepository.findByUsername_Username(username);
            return ResponseEntity.ok(groups);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาด: " + e.getMessage());
        }
    }

    //================================================================================================
    @GetMapping("/groups/{groupId}/menuCount")
    public ResponseEntity<?> getMenuCountUsingGroup(@PathVariable Integer groupId) {
        try {
            int count = menuaddongroupRepository.countMenusByGroupId(groupId);
            Map<String, Integer> response = new HashMap<>();
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดในการนับจำนวนเมนู");
        }
    }

    @PatchMapping("/groups/{groupId}/status")
    public ResponseEntity<?> toggleGroupStatus(
            @PathVariable Integer groupId,
            @RequestBody Map<String, Object> body) {

        return menuaddongroupRepository.findById(groupId)
                .map(group -> {

                    Object statusValue = body.get("status");

                    if (statusValue == null) {
                        return ResponseEntity.badRequest()
                                .body(Map.of("message", "กรุณาระบุ status"));
                    }

                    Boolean status;

                    if (statusValue instanceof Boolean) {
                        status = (Boolean) statusValue;
                    } else if (statusValue instanceof String) {
                        status = Boolean.parseBoolean((String) statusValue);
                    } else if (statusValue instanceof Number) {
                        status = ((Number) statusValue).intValue() == 1;
                    } else {
                        return ResponseEntity.badRequest()
                                .body(Map.of("message", "ค่า status ไม่ถูกต้อง"));
                    }

                    group.setStatus(status);
                    menuaddongroupRepository.save(group);

                    return ResponseEntity.ok(
                            Map.of("message", "อัปเดตสถานะกลุ่มตัวเลือกสำเร็จ")
                    );
                })
                .orElseGet(() ->
                        ResponseEntity.notFound().build()
                );
    }

    //================================================================================================

}