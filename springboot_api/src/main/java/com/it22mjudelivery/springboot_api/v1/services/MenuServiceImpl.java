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
            String restaurantId = (String) requestData.get("restaurantId");
//            Integer typeMenuId = (Integer) requestData.get("typeMenuId");

            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));
//            TypeMenu typeMenu = typeMenuRepository.findById(typeMenuId)
//                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));

//=============================================================
            // ใหม่ — รองรับทั้ง typeMenuId เดิม และ typeMenuName ใหม่
            TypeMenu typeMenu;
            Integer typeMenuId = requestData.get("typeMenuId") != null
                    ? (Integer) requestData.get("typeMenuId") : null;
            String typeMenuName = (String) requestData.get("typeMenuName");

            if (typeMenuId != null) {
                typeMenu = typeMenuRepository.findById(typeMenuId)
                        .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
            } else if (typeMenuName != null && !typeMenuName.isBlank()) {
                // สร้างประเภทใหม่แล้วบันทึกเลย
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(typeMenuName);
                typeMenu = typeMenuRepository.save(newType);
            } else {
                throw new RuntimeException("กรุณาระบุประเภทเมนู");
            }

//==========================================================================

            // 🌟 แกะค่าพาร์ท URL รูปภาพที่ได้จาก Flutter (รองรับทั้งกรณีพิมพ์เล็กพิมพ์ใหญ่)
            String finalImageUrl = "";
            if (requestData.containsKey("imageUrl")) {
                finalImageUrl = (String) requestData.get("imageUrl");
            } else if (requestData.containsKey("imageurl")) {
                finalImageUrl = (String) requestData.get("imageurl");
            }

            // 2. เซฟข้อมูลพื้นฐานลงตาราง Menu
            Menu menu = Menu.builder()
                    .menuname((String) requestData.get("menuname"))
                    .description((String) requestData.get("description"))
                    .price(Double.parseDouble(requestData.get("price").toString()))

                    // ✅ ดึงรูปภาพจากตัวแปรที่เราสกัดไว้มาเซฟลง DB จริงแทนค่าว่างของเดิม
                    .imageurl(finalImageUrl)

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

    @Transactional
    public boolean updateMenuWithAddons(Map<String, Object> requestData) {
        try {
            // 1. ดึง MenuId มาเพื่อค้นหาของเดิม
            Integer menuId = (Integer) requestData.get("menuId");
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดต"));

            // 2. อัปเดตข้อมูลพื้นฐาน
            menu.setMenuname((String) requestData.get("menuname"));
            menu.setDescription((String) requestData.get("description"));
            menu.setPrice(Double.parseDouble(requestData.get("price").toString()));
            menu.setStatus((boolean) requestData.get("status"));

            // จัดการรูปภาพ
            if (requestData.containsKey("imageUrl")) {
                menu.setImageurl((String) requestData.get("imageUrl"));
            } else if (requestData.containsKey("imageurl")) {
                menu.setImageurl((String) requestData.get("imageurl"));
            }

            // 3. จัดการ TypeMenu (ดึงตาม logic เดิมของคุณ Kaito)
            Integer typeMenuId = (Integer) requestData.get("typeMenuId");
            TypeMenu typeMenu = typeMenuRepository.findById(typeMenuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
            menu.setTypemenu(typeMenu);

            menuRepository.save(menu);

            // 4. ล้าง Addon เดิมออกให้หมดก่อน (เพื่อเขียนใหม่)
            // หมายเหตุ: ต้องเพิ่มเมธอด deleteByMenu ใน MenuaddongroupRepository
            menuaddongroupRepository.deleteByMenu(menu);

            // 5. บันทึก Addon ใหม่เข้าไป (ใช้ Logic เดิมที่คุณมี)
            if (requestData.containsKey("addonGroups")) {
                List<Map<String, Object>> groupsData = (List<Map<String, Object>>) requestData.get("addonGroups");
                for (Map<String, Object> groupMap : groupsData) {
                    Menuaddongroup group = Menuaddongroup.builder()
                            .addongroupname((String) groupMap.get("addongroupname"))
                            .maxselect((int) groupMap.get("maxselect"))
                            .isRequired((boolean) groupMap.get("isRequired"))
                            .menu(menu)
                            .build();
                    menuaddongroupRepository.save(group);

                    List<Map<String, Object>> detailsData = (List<Map<String, Object>>) groupMap.get("details");
                    for (Map<String, Object> detailMap : detailsData) {
                        Integer addonId = (Integer) detailMap.get("addonid");
                        Addonmenu addonmenu;

                        if (addonId == null) {
                            addonmenu = Addonmenu.builder()
                                    .addonname((String) detailMap.get("customaddonname"))
                                    .build();
                            addonmenuRepository.save(addonmenu);
                        } else {
                            addonmenu = addonmenuRepository.findById(addonId)
                                    .orElseThrow(() -> new RuntimeException("ไม่พบตัวเลือกเสริม"));
                        }

                        Menuaddondetail detail = Menuaddondetail.builder()
                                .addonprice(Double.parseDouble(detailMap.get("addonprice").toString()))
                                .menuaddongroup(group)
                                .addonmenu(addonmenu)
                                .build();
                        menuaddondetailRepository.save(detail);
                    }
                }
            }
            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e);
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }


}
