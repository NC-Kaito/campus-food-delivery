package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

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

    private double extractExtraPrice(Map<String, Object> requestData) {
        Object raw = requestData.containsKey("extraprice")
                ? requestData.get("extraprice")
                : requestData.get("extraPrice");
        if (raw == null) return 0.0;
        return Double.parseDouble(raw.toString());
    }

    @Transactional
    public boolean saveMenuWithAddons(Map<String, Object> requestData) {
        try {
            String restaurantId = (String) requestData.get("restaurantId");
            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            TypeMenu typeMenu;
            Integer typeMenuId = requestData.get("typeMenuId") != null
                    ? (Integer) requestData.get("typeMenuId") : null;
            String typeMenuName = (String) requestData.get("typeMenuName");

            if (typeMenuId != null) {
                typeMenu = typeMenuRepository.findById(typeMenuId)
                        .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
            } else if (typeMenuName != null && !typeMenuName.isBlank()) {
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(typeMenuName);
                typeMenu = typeMenuRepository.save(newType);
            } else {
                throw new RuntimeException("กรุณาระบุประเภทเมนู");
            }

            String finalImageUrl = "";
            if (requestData.containsKey("imageUrl")) {
                finalImageUrl = (String) requestData.get("imageUrl");
            } else if (requestData.containsKey("imageurl")) {
                finalImageUrl = (String) requestData.get("imageurl");
            }

            // 1. สร้างและเซฟข้อมูลพื้นฐานลงตาราง Menu ก่อนเพื่อให้แตกไอดีหลักออกมารอ
            Menu menu = Menu.builder()
                    .menuname((String) requestData.get("menuname"))
                    .description((String) requestData.get("description"))
                    .price(Double.parseDouble(requestData.get("price").toString()))
                    .imageurl(finalImageUrl)
                    .status((boolean) requestData.get("status"))
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            menu = menuRepository.save(menu);

            // 2. เซฟข้อมูลกลุ่มตัวเลือกเสริมลงตาราง Menuaddongroup
            if (requestData.containsKey("addonGroups")) {
                List<Map<String, Object>> groupsData = (List<Map<String, Object>>) requestData.get("addonGroups");
                Set<Menuaddongroup> addonGroupsSet = new HashSet<>(); // ตระเตรียมเซ็ตไว้ผูกตารางกลาง

                for (Map<String, Object> groupMap : groupsData) {
                    // 🎯 แก้จุดบั๊ก: เอา .menu(menu) ออกไปเนื่องจากเปลี่ยนโครงสร้างเป็น @ManyToMany แล้ว
                    Menuaddongroup group = Menuaddongroup.builder()
                            .addongroupname((String) groupMap.get("addongroupname"))
                            .is_multiple_choice((boolean) groupMap.get("is_multiple_choice"))
                            .build();

                    Menuaddongroup savedGroup = menuaddongroupRepository.save(group);
                    addonGroupsSet.add(savedGroup);

                    // 3. วนลูปเซฟรายช้อยส์ย่อยลงตาราง Menuaddondetail พ่วงราคาปกติ
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
                                    .orElseThrow(() -> new RuntimeException("ไม่พบตัวเลือกเสริมช้อยส์นี้ในฐานข้อมูล"));
                        }

                        Menuaddondetail detail = Menuaddondetail.builder()
                                .addonprice(Double.parseDouble(detailMap.get("addonprice").toString()))
                                .menuaddongroup(savedGroup)
                                .addonmenu(addonmenu)
                                .build();

                        menuaddondetailRepository.save(detail);
                    }
                }

                // 🌟 4. ผูกกลุ่มแอดออนกลับเข้าหาตัว Menu หลักเพื่อสั่งอัปเดตข้อมูลลงตารางกลาง (menu_addongroups)
                menu.setMenuAddonGroups(addonGroupsSet);
                menuRepository.save(menu);
            }
            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนูและแอดออน: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    //=============================================================================
    @Transactional
    public boolean saveMenu(MenuDto requestData) {
        try {
            // =======================================================
            // 1. ค้นหาร้านค้า (restaurant)
            // =======================================================
            String restaurantId = requestData.getUsername();
            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            // =======================================================
            // 2. จัดการหมวดหมู่เมนู (typeMenu)
            // =======================================================
            TypeMenu typeMenu;
            Integer typeMenuId = requestData.getTypeMenuId();
            String typeMenuName = requestData.getTypeMenuName();

            if (typeMenuId != null) {
                typeMenu = typeMenuRepository.findById(typeMenuId)
                        .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
            } else if (typeMenuName != null && !typeMenuName.isBlank()) {
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(typeMenuName);
                typeMenu = typeMenuRepository.save(newType);
            } else {
                throw new RuntimeException("กรุณาระบุประเภทเมนู");
            }

            String finalImageUrl = requestData.getImageurl() != null ? requestData.getImageurl() : "";

            // =======================================================
            // 3. บันทึกข้อมูลเมนูหลัก
            // =======================================================
            Menu menu = Menu.builder()
                    .menuname(requestData.getMenuname())
                    .description(requestData.getDescription())
                    .price(requestData.getPrice() != null ? requestData.getPrice() : 0.0)
                    .imageurl(finalImageUrl)
                    .status(requestData.isStatus())
                    .restaurant(restaurant) // 👈 ตอนนี้ตัวแปร restaurant มีให้ใช้แล้ว
                    .typemenu(typeMenu)     // 👈 ตอนนี้ตัวแปร typeMenu มีให้ใช้แล้ว
                    .build();

            menu = menuRepository.save(menu);

            // =======================================================
            // 4. จัดการผูก Add-on Groups เข้ากับเมนู (โดยไม่สร้างใหม่)
            // =======================================================
            Set<Menuaddongroup> groupsForThisMenu = new HashSet<>();

            // ตรวจสอบว่ามีส่ง addonGroupIds (แบบ List ตัวเลข) มาหรือไม่
            if (requestData.getAddonGroupIds() != null && !requestData.getAddonGroupIds().isEmpty()) {
                for (Integer groupId : requestData.getAddonGroupIds()) {
                    // ดึงกลุ่ม Add-on เดิมที่มีอยู่แล้วในคลัง
                    Menuaddongroup existingGroup = menuaddongroupRepository.findById(groupId)
                            .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupId));

                    groupsForThisMenu.add(existingGroup);
                }
            }
            // เผื่อรับมาเป็น Array Object จาก addonGroups (Fallback)
            else if (requestData.getAddonGroups() != null && !requestData.getAddonGroups().isEmpty()) {
                for (var groupDto : requestData.getAddonGroups()) {
                    if (groupDto.getAddongroupid() != null) {
                        Menuaddongroup existingGroup = menuaddongroupRepository.findById(groupDto.getAddongroupid())
                                .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupDto.getAddongroupid()));

                        groupsForThisMenu.add(existingGroup);
                    }
                }
            }

            // หากมีกลุ่มที่ถูกเลือก ให้จับผูกเข้ากับเมนูนี้
            if (!groupsForThisMenu.isEmpty()) {
                menu.setMenuAddonGroups(groupsForThisMenu);
                menuRepository.save(menu);
            }

            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนู " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }
    @Transactional
    public boolean updateMenuByRestaurant(Map<String, Object> requestData) {
        try {
            Integer menuId = (Integer) requestData.get("menuId");
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดต"));

            menu.setMenuname((String) requestData.get("menuname"));
            menu.setDescription((String) requestData.get("description"));
            menu.setPrice(Double.parseDouble(requestData.get("price").toString()));
            menu.setStatus((boolean) requestData.get("status"));

            if (requestData.containsKey("imageUrl")) {
                menu.setImageurl((String) requestData.get("imageUrl"));
            } else if (requestData.containsKey("imageurl")) {
                menu.setImageurl((String) requestData.get("imageurl"));
            }

            Integer typeMenuId = requestData.get("typeMenuId") != null
                    ? (Integer) requestData.get("typeMenuId") : null;
            String typeMenuName = (String) requestData.get("typeMenuName");

            TypeMenu typeMenu;
            if (typeMenuId != null) {
                typeMenu = typeMenuRepository.findById(typeMenuId)
                        .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
            } else if (typeMenuName != null && !typeMenuName.isBlank()) {
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(typeMenuName);
                typeMenu = typeMenuRepository.save(newType);
            } else {
                throw new RuntimeException("กรุณาระบุประเภทเมนู");
            }
            menu.setTypemenu(typeMenu);

            // ==========================================================
            // 🎯 เพิ่มส่วนจัดการอัปเดต Add-on ที่ถูกผูกกับเมนู
            // ==========================================================
            if (requestData.containsKey("addonGroupIds")) {
                List<?> rawIds = (List<?>) requestData.get("addonGroupIds");
                Set<Menuaddongroup> newAddonGroups = new HashSet<>();

                if (rawIds != null && !rawIds.isEmpty()) {
                    for (Object rawId : rawIds) {
                        Integer groupId = Integer.parseInt(rawId.toString());
                        Menuaddongroup group = menuaddongroupRepository.findById(groupId)
                                .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupId));
                        newAddonGroups.add(group);
                    }
                }

                // นำ Set ที่ได้ไปอัปเดต (ถ้า List ว่างเปล่า = ลบการผูกทั้งหมด)
                menu.setMenuAddonGroups(newAddonGroups);
            }

            menuRepository.save(menu);
            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e);
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }

    @Transactional
    public boolean deleteMenu(int menuId) {
        return menuRepository.findById(menuId).map(menu -> {
            if (menu.getMenuAddonGroups() != null && !menu.getMenuAddonGroups().isEmpty()) {
                menu.getMenuAddonGroups().clear();
                menuRepository.save(menu);
            }
            menuRepository.delete(menu);
            return true;
        }).orElse(false);
    }


    //==================================================================
    // =============================================================================
    // 🎯 เพิ่มฟังก์ชันสำหรับอัปเดตการผูกเมนูกับกลุ่มตัวเลือกเสริม (ตารางกลาง menu_addongroups)
    @Transactional
    @Override
    public boolean updateMenuMapping(Integer menuId, List<Integer> addonGroupIds) {
        try {
            // 1. ค้นหา Menu เดิมจากฐานข้อมูล
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดตการผูกกลุ่มตัวเลือก"));

            // 2. ดึงกลุ่มตัวเลือกทั้งหมดที่ผู้ใช้เพิ่งกด "ใช้"
            Set<Menuaddongroup> selectedGroups = new HashSet<>();
            if (addonGroupIds != null && !addonGroupIds.isEmpty()) {
                // JPA มีคำสั่ง findAllById มาให้ใช้ได้เลย ประหยัดแรงมาก
                List<Menuaddongroup> groups = menuaddongroupRepository.findAllById(addonGroupIds);
                selectedGroups.addAll(groups);
            }

            // 3. อัปเดตความสัมพันธ์ให้ Menu (ทับของเก่าไปเลย JPA จะไปเคลียร์ตารางกลางให้อัตโนมัติ)
            menu.setMenuAddonGroups(selectedGroups);
            menuRepository.save(menu);

            return true;
        } catch (Exception e) {
            e.printStackTrace(); // ← เพิ่มไว้ดู stack trace จริงตอน debug (ลบออกทีหลังได้)
            System.err.println("เกิดข้อผิดพลาดในการอัปเดต Mapping ตารางกลาง: " + e.getMessage());
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }

//    @Override
//    public Set<Menuaddongroup> getAddonsByTypeMenuId(int id) {
//        TypeMenu typeMenu = typeMenuRepository.findById(id)
//                .orElseThrow(() -> new RuntimeException("ไม่พบประเภทอาหาร ID: " + id));
//
//        // ดึงรายการ Add-on ที่ผูกไว้ส่งกลับไปให้ Flutter
//        return typeMenu.getDefaultAddonGroups();
//    }
}