package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class MenuServiceImpl implements MenuService {

    private static final List<String> ACTIVE_STATUSES =
            List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");

    private final MenuRepository menuRepository;
    private final RestaurantRepository restaurantRepository;
    private final TypeMenuRepository typeMenuRepository;
    private final OptionGroupRepository optionGroupRepository;
    private final OptionRepository optionRepository;
    private final OrderRepository orderRepository;
    private final OrderDetailRepository orderDetailRepository;

    public List<Menu> getMenusByRestaurant(String username) {
        return menuRepository.findByRestaurant_username(username);
    }

    public List<Menu> getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId) {
        return menuRepository.findByRestaurant_usernameAndTypemenu_typemenuId(username, typeMenuId);
    }

    // อนุญาตให้ "เปิด-ปิด" เมนูได้ตลอดเวลา เผื่อกรณีวัตถุดิบหมดกะทันหัน
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

    // ตรวจว่าร้านมีออเดอร์ที่กำลังดำเนินการอยู่หรือไม่ ถ้ามีให้ throw
    private void assertNoActiveOrders(Menu menu, String actionText) {
        String restaurantUsername = menu.getRestaurant().getUsername();
        List<Order> activeOrders = orderRepository
                .findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, ACTIVE_STATUSES);
        if (activeOrders != null && !activeOrders.isEmpty()) {
            throw new RuntimeException("ไม่สามารถ" + actionText + "ได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
        }
    }

    // หาประเภทเมนูจาก id หรือชื่อ (ถ้าไม่มีชื่อนี้ให้สร้างใหม่)
    private TypeMenu resolveTypeMenu(Integer typeMenuId, String typeMenuName) {
        String name = typeMenuName != null ? typeMenuName.trim() : null;

        if (typeMenuId != null) {
            return typeMenuRepository.findById(typeMenuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
        } else if (name != null && !name.isBlank()) {
            return typeMenuRepository.findByTypemenuName(name).orElseGet(() -> {
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(name);
                return typeMenuRepository.save(newType);
            });
        }
        throw new RuntimeException("กรุณาระบุประเภทเมนู");
    }

    @Override
    @Transactional
    @SuppressWarnings("unchecked")
    public boolean saveMenuWithAddons(Map<String, Object> requestData) {
        try {
            String restaurantId = (String) requestData.get("restaurantId");
            Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            Integer typeMenuId = requestData.get("typeMenuId") != null
                    ? Integer.parseInt(requestData.get("typeMenuId").toString()) : null;
            TypeMenu typeMenu = resolveTypeMenu(typeMenuId, (String) requestData.get("typeMenuName"));

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

            if (requestData.containsKey("addonGroups") && requestData.get("addonGroups") != null) {
                List<Map<String, Object>> groupsData =
                        (List<Map<String, Object>>) requestData.get("addonGroups");

                for (Map<String, Object> groupMap : groupsData) {
                    // Optiongroup ตอนนี้เป็นของเมนูเดียว (menuid not null) จึงต้องผูก menu เสมอ
                    Optiongroup group = Optiongroup.builder()
                            .optiongroupname((String) groupMap.get("addongroupname"))
                            .is_required(groupMap.get("is_required") != null
                                    && (boolean) groupMap.get("is_required"))
                            .is_multiple_choice(groupMap.get("is_multiple_choice") != null
                                    && (boolean) groupMap.get("is_multiple_choice"))
                            .menu(menu)
                            .build();

                    Optiongroup savedGroup = (Optiongroup) optionGroupRepository.save(group);

                    List<Map<String, Object>> detailsData =
                            (List<Map<String, Object>>) groupMap.get("details");
                    if (detailsData == null) continue;

                    for (Map<String, Object> detailMap : detailsData) {
                        // Option ใหม่เป็นของกลุ่มเดียว สร้างใหม่ทุกครั้ง (ไม่แชร์ข้ามกลุ่ม)
                        // หมายเหตุ: Option ยังไม่มี field ชื่อ จึงยังเก็บ customaddonname ไม่ได้
                        Option option = Option.builder()
                                .optionprice(Double.parseDouble(detailMap.get("addonprice").toString()))
                                .optiongroup(savedGroup)
                                .build();

                        optionRepository.save(option);
                    }
                }
            }
            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนูและแอดออน: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    public boolean saveMenu(MenuDto requestData) {
        try {
            Restaurant restaurant = restaurantRepository.findByUsername(requestData.getUsername())
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            TypeMenu typeMenu = resolveTypeMenu(requestData.getTypeMenuId(), requestData.getTypeMenuName());

            String finalImageUrl = requestData.getImageurl() != null ? requestData.getImageurl() : "";

            Menu menu = Menu.builder()
                    .menuname(requestData.getMenuname())
                    .description(requestData.getDescription())
                    .price(requestData.getPrice() != null ? requestData.getPrice() : 0.0)
                    .price2(requestData.getPrice2())
                    .price3(requestData.getPrice3())
                    .imageurl(finalImageUrl)
                    .status(requestData.isStatus())
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            // 1. บันทึกเมนูก่อนเพื่อสร้าง menuid
            Menu savedMenu = menuRepository.save(menu);

            // 2. 🎯 บันทึก Optiongroup และ Option โดยใช้ Repository ที่มีอยู่แล้ว
            if (requestData.getOptionGroups() != null && !requestData.getOptionGroups().isEmpty()) {
                for (com.it22mjudelivery.springboot_api.v1.dtos.OptionGroupRequestDTO groupDto : requestData.getOptionGroups()) {
                    Optiongroup group = Optiongroup.builder()
                            .optiongroupname(groupDto.getOptiongroupname())
                            .is_required(groupDto.is_required())
                            .is_multiple_choice(groupDto.is_multiple_choice())
                            .menu(savedMenu) // ผูกกับเมนู
                            .build();

                    Optiongroup savedGroup = optionGroupRepository.save(group);

                    if (groupDto.getOptions() != null) {
                        for (Object rawOpt : groupDto.getOptions()) {
                            String optName = "";
                            double optPrice = 0.0;

                            if (rawOpt instanceof com.it22mjudelivery.springboot_api.v1.dtos.OptionGroupRequestDTO.OptionDetailDTO) {
                                var optDto = (com.it22mjudelivery.springboot_api.v1.dtos.OptionGroupRequestDTO.OptionDetailDTO) rawOpt;
                                optName = optDto.getOptionname();
                                optPrice = optDto.getOptionprice();
                            } else if (rawOpt instanceof java.util.Map) {
                                var map = (java.util.Map<?, ?>) rawOpt;
                                optName = map.get("optionname") != null ? map.get("optionname").toString() : "";
                                optPrice = map.get("optionprice") != null ? Double.parseDouble(map.get("optionprice").toString()) : 0.0;
                            }

                            Option option = Option.builder()
                                    .optionname(optName)
                                    .optionprice(optPrice)
                                    .optiongroup(savedGroup)
                                    .build();

                            optionRepository.save(option);
                        }
                    }
                }
            }

            return true;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนู: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    @SuppressWarnings("unchecked")
    public boolean updateMenuByRestaurant(Map<String, Object> requestData) {
        try {
            Integer menuId = Integer.parseInt(
                    requestData.containsKey("menuId") ? requestData.get("menuId").toString() : requestData.get("menuid").toString()
            );
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดต"));

            assertNoActiveOrders(menu, "แก้ไขเมนู");

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
                    ? Integer.parseInt(requestData.get("typeMenuId").toString()) : null;
            menu.setTypemenu(resolveTypeMenu(typeMenuId, (String) requestData.get("typeMenuName")));

            menuRepository.save(menu);

            // 🎯 จัดการอัปเดต Option Groups และ Options ตอนแก้ไข
            if (requestData.containsKey("optionGroups") && requestData.get("optionGroups") != null) {
                // ลบของเดิมออกก่อน
                List<Optiongroup> oldGroups = optionGroupRepository.findByMenu(menu);
                for (Optiongroup og : oldGroups) {
                    optionRepository.deleteByOptiongroup(og);
                }
                optionGroupRepository.deleteAll(oldGroups);

                // บันทึกชุดใหม่เข้าไป
                List<Map<String, Object>> groupsData = (List<Map<String, Object>>) requestData.get("optionGroups");
                for (Map<String, Object> grpMap : groupsData) {
                    Optiongroup newGroup = Optiongroup.builder()
                            .optiongroupname((String) grpMap.get("optiongroupname"))
                            .is_required(grpMap.get("is_required") != null && (boolean) grpMap.get("is_required"))
                            .is_multiple_choice(grpMap.get("is_multiple_choice") != null && (boolean) grpMap.get("is_multiple_choice"))
                            .menu(menu)
                            .build();

                    Optiongroup savedGroup = optionGroupRepository.save(newGroup);

                    List<Map<String, Object>> optionsList = (List<Map<String, Object>>) grpMap.get("options");
                    if (optionsList != null) {
                        for (Map<String, Object> optMap : optionsList) {
                            Option option = Option.builder()
                                    .optionname((String) optMap.get("optionname"))
                                    .optionprice(Double.parseDouble(optMap.get("optionprice").toString()))
                                    .optiongroup(savedGroup)
                                    .build();

                            optionRepository.save(option);
                        }
                    }
                }
            }

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e);
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }
    @Override
    @Transactional
    public boolean deleteMenu(int menuId) {
        try {
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการลบ"));

            assertNoActiveOrders(menu, "ลบเมนู");

            List<OrderDetail> oldOrderDetails = orderDetailRepository.findByMenu(menu);

            // Orderdetailoption อ้าง Option เป็น PK (null ไม่ได้)
            // ถ้าเมนูนี้เคยถูกสั่งพร้อมตัวเลือกเสริม จะลบ Option ไม่ได้
            if (oldOrderDetails != null) {
                for (OrderDetail od : oldOrderDetails) {
                    if (od.getOrderDetailOptions() != null && !od.getOrderDetailOptions().isEmpty()) {
                        throw new RuntimeException(
                                "ไม่สามารถลบเมนูได้ เนื่องจากเคยมีการสั่งพร้อมตัวเลือกเสริม กรุณาปิดการขายเมนูแทน");
                    }
                }
                // ปลดความสัมพันธ์จากประวัติออเดอร์เก่า (มี Snapshot แสดงแทนแล้ว)
                for (OrderDetail od : oldOrderDetails) {
                    od.setMenu(null);
                }
                orderDetailRepository.saveAll(oldOrderDetails);
            }

            // ลบ Option และ Optiongroup ของเมนูนี้ก่อน (ติด FK)
            List<Optiongroup> groups = optionGroupRepository.findByMenu(menu);
            for (Optiongroup group : groups) {
                optionRepository.deleteAll(optionRepository.findByOptiongroup(group));
            }
            optionGroupRepository.deleteAll(groups);

            menuRepository.delete(menu);
            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการลบข้อมูล: " + e.getMessage());
        }
    }

    /**
     * @deprecated โครงสร้างใหม่ Optiongroup เป็นของเมนูเดียว ไม่มีตารางกลาง Menu-Group แล้ว
     * เมธอดนี้จึงไม่ทำอะไรนอกจากตรวจสอบสิทธิ์ ให้ลบออกจาก MenuService/Controller เมื่อ Flutter เลิกเรียก
     */
    @Deprecated
    @Override
    @Transactional
    public boolean updateMenuMapping(Integer menuId, List<Integer> addonGroupIds) {
        Menu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดตการผูกกลุ่มตัวเลือก"));

        assertNoActiveOrders(menu, "แก้ไขเมนู");

        System.out.println("updateMenuMapping ถูกยกเลิกแล้ว (Optiongroup ผูกกับเมนูเดียว) menuId=" + menuId);
        return true;
    }
}