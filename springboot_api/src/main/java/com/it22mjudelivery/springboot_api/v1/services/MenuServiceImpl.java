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

    // 🎯 1. ประกาศใช้ OrderRepository เพื่อดึงข้อมูลออเดอร์ปัจจุบัน
    private final OrderRepository orderRepository;

    private final OrderDetailRepository orderDetailRepository;

    public List getMenusByRestaurant(String username){
        return menuRepository.findByRestaurant_username(username);
    }

    public List getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId) {
        return menuRepository.findByRestaurant_usernameAndTypemenu_typemenuId(username, typeMenuId);
    }

    // 💡 อนุญาตให้ "เปิด-ปิด" เมนูได้ตลอดเวลา เผื่อกรณีวัตถุดิบหมดกะทันหัน
    public boolean updateMenuStatus(int menuId, boolean status) {
        return menuRepository.findById(menuId).map(menu -> {
            menu.setStatus(status);
            menuRepository.save(menu);
            return true;
        }).orElse(false);
    }

    private double extractExtraPrice(Map requestData) {
        Object raw = requestData.containsKey("extraprice")
                ? requestData.get("extraprice")
                : requestData.get("extraPrice");
        if (raw == null) return 0.0;
        return Double.parseDouble(raw.toString());
    }

    @Transactional
    public boolean saveMenuWithAddons(Map requestData) {
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

            if (requestData.containsKey("addonGroups")) {
                // 🎯 ระบุชนิดตัวแปร List และ Map ให้ครบถ้วน
                List< Map< String, Object > > groupsData = (List< Map< String, Object > >) requestData.get("addonGroups");
                Set< Menuaddongroup > addonGroupsSet = new HashSet<>();

                for (Map< String, Object > groupMap : groupsData) {
                    Menuaddongroup group = Menuaddongroup.builder()
                            .addongroupname((String) groupMap.get("addongroupname"))
                            .is_multiple_choice((boolean) groupMap.get("is_multiple_choice"))
                            .build();

                    Menuaddongroup savedGroup = menuaddongroupRepository.save(group);
                    addonGroupsSet.add(savedGroup);

                    // 🎯 ระบุชนิดตัวแปร List และ Map สำหรับ detailsData
                    List< Map< String, Object > > detailsData = (List< Map< String, Object > >) groupMap.get("details");
                    for (Map< String, Object > detailMap : detailsData) {
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

                menu.setMenuAddonGroups(addonGroupsSet);
                menuRepository.save(menu);
            }  return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนูและแอดออน: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    @Transactional
    public boolean saveMenu(MenuDto requestData) {
        try {
            String restaurantId = requestData.getUsername();
            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

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

            Menu menu = Menu.builder()
                    .menuname(requestData.getMenuname())
                    .description(requestData.getDescription())
                    .price(requestData.getPrice() != null ? requestData.getPrice() : 0.0)
                    .imageurl(finalImageUrl)
                    .status(requestData.isStatus())
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            menu = menuRepository.save(menu);

            Set groupsForThisMenu = new HashSet<>();

            if (requestData.getAddonGroupIds() != null && !requestData.getAddonGroupIds().isEmpty()) {
                for (Integer groupId : requestData.getAddonGroupIds()) {
                    Menuaddongroup existingGroup = menuaddongroupRepository.findById(groupId)
                            .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupId));
                    groupsForThisMenu.add(existingGroup);
                }
            } else if (requestData.getAddonGroups() != null && !requestData.getAddonGroups().isEmpty()) {
                for (var groupDto : requestData.getAddonGroups()) {
                    if (groupDto.getAddongroupid() != null) {
                        Menuaddongroup existingGroup = menuaddongroupRepository.findById(groupDto.getAddongroupid())
                                .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupDto.getAddongroupid()));
                        groupsForThisMenu.add(existingGroup);
                    }
                }
            }

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
    public boolean updateMenuByRestaurant(Map requestData) {
        try {
            Integer menuId = (Integer) requestData.get("menuId");
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดต"));

            // 🎯 2. ตรวจสอบว่าร้านค้านี้มีออเดอร์กำลังทำงานอยู่หรือไม่ ก่อนให้สิทธิ์แก้ไขเมนู
            String restaurantUsername = menu.getRestaurant().getUsername();
            List activeStatuses = List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            List activeOrders = orderRepository.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, activeStatuses);

            if (activeOrders != null && !activeOrders.isEmpty()) {
                throw new RuntimeException("ไม่สามารถแก้ไขเมนูได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
            }

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

            if (requestData.containsKey("addonGroupIds")) {
                List rawIds = (List) requestData.get("addonGroupIds");
                Set newAddonGroups = new HashSet<>();

                if (rawIds != null && !rawIds.isEmpty()) {
                    for (Object rawId : rawIds) {
                        Integer groupId = Integer.parseInt(rawId.toString());
                        Menuaddongroup group = menuaddongroupRepository.findById(groupId)
                                .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริม ID: " + groupId));
                        newAddonGroups.add(group);
                    }
                }
                menu.setMenuAddonGroups(newAddonGroups);
            }

            menuRepository.save(menu);
            return true;
        } catch (RuntimeException e) {
            throw e; // โยน RuntimeException ออกไปให้ Controller ส่งกลับไปยัง Flutter ทันที
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e);
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }

    @Transactional
    public boolean deleteMenu(int menuId) {
        try {
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการลบ"));

            // 1. ตรวจสอบว่าร้านค้านี้มีออเดอร์กำลังทำงานอยู่หรือไม่
            String restaurantUsername = menu.getRestaurant().getUsername();
            List< String > activeStatuses = List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            List< Order > activeOrders = orderRepository.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, activeStatuses);

            if (activeOrders != null && !activeOrders.isEmpty()) {
                throw new RuntimeException("ไม่สามารถลบเมนูได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
            }

            // 🎯 2. ปลดล็อก Foreign Key จากประวัติออเดอร์เก่า
            // ค้นหา OrderDetail ทั้งหมดที่เคยสั่งเมนูนี้ แล้วเซ็ต menu ให้เป็น null
            // (ประวัติจะไม่พังเพราะเรามี Snapshot Data โชว์แทนแล้ว)
            List< OrderDetail > oldOrderDetails = orderDetailRepository.findByMenu(menu);
            if (oldOrderDetails != null && !oldOrderDetails.isEmpty()) {
                for (OrderDetail od : oldOrderDetails) {
                    od.setMenu(null);
                }
                orderDetailRepository.saveAll(oldOrderDetails);
            }

            // 3. เคลียร์ความสัมพันธ์กับกลุ่ม Add-on (ตารางกลาง)
            if (menu.getMenuAddonGroups() != null && !menu.getMenuAddonGroups().isEmpty()) {
                menu.getMenuAddonGroups().clear();
                menuRepository.save(menu);
            }

            // 4. ลบเมนูได้อย่างปลอดภัย ไม่ติด Error SQL แล้ว!
            menuRepository.delete(menu);
            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการลบข้อมูล: " + e.getMessage());
        }
    }
    @Transactional
    @Override
    public boolean updateMenuMapping(Integer menuId, List addonGroupIds) {
        try {
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดตการผูกกลุ่มตัวเลือก"));

            // 🎯 4. เช็กล็อกการผูก Add-on ด้วยเผื่อไว้
            String restaurantUsername = menu.getRestaurant().getUsername();
            List activeStatuses = List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            List activeOrders = orderRepository.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, activeStatuses);

            if (activeOrders != null && !activeOrders.isEmpty()) {
                throw new RuntimeException("ไม่สามารถแก้ไขเมนูได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
            }

            Set selectedGroups = new HashSet<>();
            if (addonGroupIds != null && !addonGroupIds.isEmpty()) {
                List groups = menuaddongroupRepository.findAllById(addonGroupIds);
                selectedGroups.addAll(groups);
            }

            menu.setMenuAddonGroups(selectedGroups);
            menuRepository.save(menu);

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println("เกิดข้อผิดพลาดในการอัปเดต Mapping ตารางกลาง: " + e.getMessage());
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }
}