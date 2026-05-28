package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.antlr.v4.runtime.misc.LogManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class MenuServiceImpl implements MenuService {
    private final MenuRepository menuRepository;

    private final RestaurantRepository restaurantRepository;
    private final TypeMenuRepository typeMenuRepository;
    private final MenuaddongroupRepository menuaddongroupRepository;
    private final AddonmenuRepository addonmenuRepository;
    private final MenuaddondetailRepository menuaddondetailRepository;

    public List<Menu> getMenusByRestaurant(String username){
        return menuRepository.findByRestaurant_username(username);
    }

    public List<Menu> getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId) {
        return menuRepository.findByRestaurant_usernameAndTypemenu_typemenuId(username, typeMenuId);
    }

    public boolean updateMenuStatus(int menuId, boolean status) {
        return menuRepository.findById(menuId).map(menu -> {
            menu.setStatus(status);
            menuRepository.save(menu);
            return true;
        }).orElse(false);
    }

    @Transactional // บังคับทำธุรกรรมฐานข้อมูล หากขั้นตอนไหนพังจะ Rollback ข้อมูลให้ปลอดภัยทันที
    public boolean saveMenuWithAddons(Map<String, Object> requestData) {
        try {
            // 1. ตรวจสอบและดึงข้อมูลร้านค้าและประเภทเมนูหลัก
            String restaurantId = (String) requestData.get("restaurantId");
            Integer typeMenuId = (Integer) requestData.get("typeMenuId");


            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));
            TypeMenu typeMenu = typeMenuRepository.findById(typeMenuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));

            // 2. เซฟข้อมูลพื้นฐานลงตาราง Menu ก่อนเป็นอันดับแรก เพื่อสร้างไอดีเมนู (menuid) หลัก
            Menu menu = Menu.builder()
                    .menuname((String) requestData.get("menuname"))
                    .description((String) requestData.get("description"))
                    .price(Double.parseDouble(requestData.get("price").toString()))
                    .imageurl("") // ใส่ค่าว่างไว้ก่อน หรือใส่ตามระเบียบระบบจัดการอัปโหลดภาพของคุณ
                    .status((boolean) requestData.get("status"))
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            menuRepository.save(menu);

            // 3. เซฟข้อมูลกลุ่มตัวเลือกเสริมลงตาราง Menuaddongroup (หากร้านค้าเปิดใช้งาน On)
            if (requestData.containsKey("addonGroups")) {
                List<Map<String, Object>> groupsData = (List<Map<String, Object>>) requestData.get("addonGroups");

                for (Map<String, Object> groupMap : groupsData) {
                    Menuaddongroup group = Menuaddongroup.builder()
                            .addongroupname((String) groupMap.get("addongroupname"))
                            .maxselect((int) groupMap.get("maxselect"))
                            .isRequired((boolean) groupMap.get("isRequired"))
                            .menu(menu) // 🔥 เชื่อมโยงความสัมพันธ์เข้ากับตัวแปร Menu หลักเมื่อสักครู่
                            .build();

                    menuaddongroupRepository.save(group);

                    // 4. วนลูปสกัดรายช้อยส์ย่อยเพื่อเซฟลงตาราง Menuaddondetail พ่วงราคาเงินบาท
                    List<Map<String, Object>> detailsData = (List<Map<String, Object>>) groupMap.get("details");
                    for (Map<String, Object> detailMap : detailsData) {

                        Integer addonId = (Integer) detailMap.get("addonid");
                        Addonmenu addonmenu;

                        if (addonId == null) {
                            // กรณีที่ร้านค้าพิมพ์เพิ่มช้อยส์เอง ไม่มีในคลังระบบ ให้สร้างวัตถุดิบใหม่เข้าคลังกลางก่อน
                            addonmenu = Addonmenu.builder()
                                    .addonname((String) detailMap.get("customaddonname"))
                                    .build();
                            addonmenuRepository.save(addonmenu);
                        } else {
                            // กรณีเลือกมาจากระบบเซิร์ฟเวอร์ย่อยอยู่แล้ว ให้ไปดึงข้อมูล Object ตัวจริงมาจากคลัง
                            addonmenu = addonmenuRepository.findById(addonId)
                                    .orElseThrow(() -> new RuntimeException("ไม่พบตัวเลือกเสริมช้อยส์นี้ในฐานข้อมูล"));
                        }

                        // บันทึกความสัมพันธ์ลงตาราง Menuaddondetail
                        Menuaddondetail detail = Menuaddondetail.builder()
                                .addonprice(Double.parseDouble(detailMap.get("addonprice").toString()))
                                .menuaddongroup(group) // 🔥 โยงเข้าหากล่องสี่เหลี่ยมกรอบใหญ่
                                .addonmenu(addonmenu)  // 🔥 โยงเข้าหาคลังวัตถุดิบชิ้นนั้น ๆ
                                .build();

                        menuaddondetailRepository.save(detail);
                    }
                }
            }
            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนูและแอดออน: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }




}
