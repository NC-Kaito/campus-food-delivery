package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.CurryPriceDto;
import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
import com.it22mjudelivery.springboot_api.v1.dtos.OptionGroupRequestDTO;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Option;
import com.it22mjudelivery.springboot_api.v1.entities.Optiongroup;
import com.it22mjudelivery.springboot_api.v1.entities.Order;
import com.it22mjudelivery.springboot_api.v1.entities.OrderDetail;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.OptionGroupRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.OptionRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.OrderDetailRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.OrderRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class MenuServiceImpl implements MenuService {

    private static final String CURRY_TEMPLATE_MENU_NAME = "ราคามาตรฐานข้าวราดแกง";

    private static final List<String> ACTIVE_STATUSES = List.of(
            "WaitingRider",
            "WaitingRestaurant",
            "goingToRestaurant",
            "delivery",
            "arrived"
    );

    private final MenuRepository menuRepository;
    private final RestaurantRepository restaurantRepository;
    private final TypeMenuRepository typeMenuRepository;
    private final OptionGroupRepository optionGroupRepository;
    private final OptionRepository optionRepository;
    private final OrderRepository orderRepository;
    private final OrderDetailRepository orderDetailRepository;

    // ==========================================================
    // Menu retrieval
    // ==========================================================

    @Override
    public List<Menu> getMenusByRestaurant(String username) {
        List<Menu> menus = menuRepository.findByRestaurant_username(username);
        if (menus == null || menus.isEmpty()) {
            return Collections.emptyList();
        }

        // ไม่ส่ง row สำหรับเก็บราคามาตรฐานไปแสดงเป็นเมนูจริง
        return menus.stream()
                .filter(menu -> !isCurryTemplateMenu(menu))
                .toList();
    }

    @Override
    public List<Menu> getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId) {
        if (typeMenuId == null) {
            return Collections.emptyList();
        }

        List<Menu> menus = menuRepository
                .findByRestaurant_usernameAndTypemenu_typemenuId(username, typeMenuId);

        if (menus == null || menus.isEmpty()) {
            return Collections.emptyList();
        }

        return menus.stream()
                .filter(menu -> !isCurryTemplateMenu(menu))
                .toList();
    }

    // ==========================================================
    // Menu status
    // ==========================================================

    @Override
    public boolean updateMenuStatus(int menuId, boolean status) {
        return menuRepository.findById(menuId).map(menu -> {
            if (isCurryTemplateMenu(menu)) {
                return false;
            }

            menu.setStatus(status);
            menuRepository.save(menu);
            return true;
        }).orElse(false);
    }

    // ==========================================================
    // Common helpers
    // ==========================================================

    private double extractExtraPrice(Map<String, Object> requestData) {
        Object raw = requestData.containsKey("extraprice")
                ? requestData.get("extraprice")
                : requestData.get("extraPrice");
        if (raw == null) {
            return 0.0;
        }
        return Double.parseDouble(raw.toString());
    }

    private boolean toBoolean(Object raw, boolean defaultValue) {
        if (raw == null) {
            return defaultValue;
        }
        if (raw instanceof Boolean value) {
            return value;
        }
        return Boolean.parseBoolean(raw.toString());
    }

    private String toStringValue(Object raw) {
        return raw == null ? null : raw.toString();
    }

    private Integer toInteger(Object raw) {
        if (raw == null) {
            return null;
        }
        return Integer.parseInt(raw.toString());
    }

    private String getFirstString(Map<?, ?> map, String... keys) {
        for (String key : keys) {
            Object raw = map.get(key);
            if (raw != null && !raw.toString().isBlank()) {
                return raw.toString().trim();
            }
        }
        return "";
    }

    private double getFirstDouble(Map<?, ?> map, String... keys) {
        for (String key : keys) {
            Object raw = map.get(key);
            if (raw != null && !raw.toString().isBlank()) {
                return Double.parseDouble(raw.toString());
            }
        }
        return 0.0;
    }

    private void assertNoActiveOrders(Menu menu, String actionText) {
        String restaurantUsername = menu.getRestaurant().getUsername();
        List<Order> activeOrders = orderRepository
                .findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(
                        restaurantUsername,
                        ACTIVE_STATUSES
                );

        if (activeOrders != null && !activeOrders.isEmpty()) {
            throw new RuntimeException(
                    "ไม่สามารถ" + actionText + "ได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่"
            );
        }
    }

    /**
     * Resolve TypeMenu จาก id หรือชื่อ
     * - id <= 0 ให้ถือว่าไม่มี id
     * - ถ้าไม่มีชื่อในระบบให้สร้างใหม่
     */
    private TypeMenu resolveTypeMenu(Integer typeMenuId, String typeMenuName) {
        Integer safeTypeMenuId = typeMenuId != null && typeMenuId > 0
                ? typeMenuId
                : null;

        String name = typeMenuName != null ? typeMenuName.trim() : null;

        if (safeTypeMenuId != null) {
            return typeMenuRepository.findById(safeTypeMenuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนู"));
        }

        if (name != null && !name.isBlank()) {
            return typeMenuRepository.findByTypemenuName(name).orElseGet(() -> {
                TypeMenu newType = new TypeMenu();
                newType.setTypemenuName(name);
                return typeMenuRepository.save(newType);
            });
        }

        throw new RuntimeException("กรุณาระบุประเภทเมนู");
    }

    private TypeMenu resolveCurryTypeMenu(Integer typeMenuId) {
        if (typeMenuId != null && typeMenuId > 0) {
            TypeMenu type = typeMenuRepository.findById(typeMenuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบประเภทเมนูข้าวราดแกง"));

            if (!isCurryType(type)) {
                throw new RuntimeException("ประเภทเมนูที่ส่งมาไม่ใช่ข้าวราดแกง");
            }
            return type;
        }

        Optional<TypeMenu> exact = typeMenuRepository.findByTypemenuName("ข้าวราดแกง");
        if (exact.isPresent()) {
            return exact.get();
        }

        Optional<TypeMenu> similar = typeMenuRepository.findAll().stream()
                .filter(type -> {
                    String name = type.getTypemenuName() == null
                            ? ""
                            : type.getTypemenuName().trim();
                    return name.contains("ข้าวราดแกง") || name.contains("ข้าวแกง");
                })
                .findFirst();

        if (similar.isPresent()) {
            return similar.get();
        }

        // รองรับกรณีร้านตั้งราคาครั้งแรกและฐานข้อมูลยังไม่มี TypeMenu นี้
        TypeMenu newType = new TypeMenu();
        newType.setTypemenuName("ข้าวราดแกง");
        return typeMenuRepository.save(newType);
    }

    private boolean isCurryType(TypeMenu typeMenu) {
        if (typeMenu == null || typeMenu.getTypemenuName() == null) {
            return false;
        }

        String name = typeMenu.getTypemenuName().trim();
        return name.contains("ข้าวราดแกง") || name.contains("ข้าวแกง");
    }

    private boolean isCurryTemplateMenu(Menu menu) {
        return menu != null && (
                menu.isCurryPriceTemplate()
                        || CURRY_TEMPLATE_MENU_NAME.equals(menu.getMenuname())
        );
    }

    private Optional<Menu> findCurryTemplate(String restaurantUsername, TypeMenu typeMenu) {
        if (restaurantUsername == null || typeMenu == null) {
            return Optional.empty();
        }

        List<Menu> menus = menuRepository
                .findByRestaurant_usernameAndTypemenu_typemenuId(
                        restaurantUsername,
                        typeMenu.getTypemenuId()
                );

        if (menus == null) {
            return Optional.empty();
        }

        return menus.stream()
                .filter(this::isCurryTemplateMenu)
                .findFirst();
    }

    private Optional<Menu> findExistingRealCurryMenu(String restaurantUsername, TypeMenu typeMenu) {
        if (restaurantUsername == null || typeMenu == null) {
            return Optional.empty();
        }

        List<Menu> menus = menuRepository
                .findByRestaurant_usernameAndTypemenu_typemenuId(
                        restaurantUsername,
                        typeMenu.getTypemenuId()
                );

        if (menus == null) {
            return Optional.empty();
        }

        return menus.stream()
                .filter(menu -> !isCurryTemplateMenu(menu))
                .findFirst();
    }

    private Menu requireCurryTemplate(String restaurantUsername, TypeMenu typeMenu) {
        return findCurryTemplate(restaurantUsername, typeMenu)
                .orElseThrow(() -> new RuntimeException(
                        "ยังไม่ได้กำหนดราคามาตรฐานข้าวราดแกง กรุณาไปตั้งค่าราคาที่หน้า Home Restaurant ก่อน"
                ));
    }

    // ==========================================================
    // Option Groups / Options helpers
    // ==========================================================

    /**
     * บันทึก option groups จาก MenuDto
     * โครงสร้างปัจจุบันคือ Optiongroup -> Menu และ Option -> Optiongroup
     * ไม่มีตารางกลางสำหรับการผูกกลุ่มกับหลายเมนู
     */
    private void saveOptionGroupsFromDto(Menu menu, List<OptionGroupRequestDTO> groups) {
        if (groups == null || groups.isEmpty()) {
            return;
        }

        for (OptionGroupRequestDTO groupDto : groups) {
            if (groupDto == null) {
                continue;
            }

            Optiongroup group = Optiongroup.builder()
                    .optiongroupname(groupDto.getOptiongroupname())
                    .is_required(groupDto.is_required())
                    .is_multiple_choice(groupDto.is_multiple_choice())
                    .menu(menu)
                    .build();

            Optiongroup savedGroup = optionGroupRepository.save(group);

            if (groupDto.getOptions() == null) {
                continue;
            }

            for (Object rawOpt : groupDto.getOptions()) {
                String optionName = "";
                double optionPrice = 0.0;

                if (rawOpt instanceof OptionGroupRequestDTO.OptionDetailDTO optDto) {
                    optionName = optDto.getOptionname();
                    optionPrice = optDto.getOptionprice();
                } else if (rawOpt instanceof Map<?, ?> map) {
                    optionName = getFirstString(map, "optionname", "optionName", "addonname");
                    optionPrice = getFirstDouble(map, "optionprice", "optionPrice", "addonprice");
                }

                // Option ใน schema ปัจจุบันเก็บชื่อ/ราคาไว้ที่ Option
                Option option = Option.builder()
                        .optionname(optionName)
                        .optionprice(optionPrice)
                        .optiongroup(savedGroup)
                        .build();

                optionRepository.save(option);
            }
        }
    }

    /**
     * รองรับ endpoint/Flutter รุ่นเก่า saveMenuWithAddons
     * แต่เก็บลงโครงสร้างใหม่ Optiongroup + Option เหมือนกัน
     */
    @SuppressWarnings("unchecked")
    private void saveOptionGroupsFromMaps(Menu menu, Object rawGroups) {
        if (!(rawGroups instanceof List<?> groupsData)) {
            return;
        }

        for (Object rawGroup : groupsData) {
            if (!(rawGroup instanceof Map<?, ?> groupMap)) {
                continue;
            }

            String groupName = getFirstString(
                    groupMap,
                    "optiongroupname",
                    "optionGroupName",
                    "addongroupname",
                    "addonGroupName"
            );

            Optiongroup group = Optiongroup.builder()
                    .optiongroupname(groupName)
                    .is_required(toBoolean(groupMap.get("is_required"), false))
                    .is_multiple_choice(toBoolean(groupMap.get("is_multiple_choice"), false))
                    .menu(menu)
                    .build();

            Optiongroup savedGroup = optionGroupRepository.save(group);

            Object rawOptions = groupMap.containsKey("options")
                    ? groupMap.get("options")
                    : groupMap.get("details");

            if (!(rawOptions instanceof List<?> optionsList)) {
                continue;
            }

            for (Object rawOption : optionsList) {
                if (!(rawOption instanceof Map<?, ?> optionMap)) {
                    continue;
                }

                String optionName = getFirstString(
                        optionMap,
                        "optionname",
                        "optionName",
                        "addonname",
                        "addonName"
                );
                double optionPrice = getFirstDouble(
                        optionMap,
                        "optionprice",
                        "optionPrice",
                        "addonprice",
                        "addonPrice"
                );

                Option option = Option.builder()
                        .optionname(optionName)
                        .optionprice(optionPrice)
                        .optiongroup(savedGroup)
                        .build();

                optionRepository.save(option);
            }
        }
    }

    private void deleteOptionGroupsForMenu(Menu menu) {
        List<Optiongroup> groups = optionGroupRepository.findByMenu(menu);
        if (groups == null || groups.isEmpty()) {
            return;
        }

        for (Optiongroup group : groups) {
            List<Option> options = optionRepository.findByOptiongroup(group);
            if (options != null && !options.isEmpty()) {
                optionRepository.deleteAll(options);
            }
        }

        optionGroupRepository.deleteAll(groups);
    }

    private boolean hasHistoricalOptionUsage(List<OrderDetail> orderDetails) {
        if (orderDetails == null) {
            return false;
        }

        for (OrderDetail orderDetail : orderDetails) {
            if (orderDetail.getOrderDetailOptions() != null
                    && !orderDetail.getOrderDetailOptions().isEmpty()) {
                return true;
            }
        }

        return false;
    }

    // ==========================================================
    // Create menu + options
    // ==========================================================

    @Override
    @Transactional
    public boolean saveMenuWithAddons(Map<String, Object> requestData) {
        try {
            String restaurantUsername = toStringValue(
                    requestData.containsKey("restaurantId")
                            ? requestData.get("restaurantId")
                            : requestData.get("username")
            );

            Restaurant restaurant = restaurantRepository.findByUsername(restaurantUsername)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            Integer typeMenuId = toInteger(requestData.get("typeMenuId"));
            String typeMenuName = toStringValue(requestData.get("typeMenuName"));
            TypeMenu typeMenu = resolveTypeMenu(typeMenuId, typeMenuName);

            boolean isCurryMenu = isCurryType(typeMenu);

            double price;
            Double price2 = null;
            Double price3 = null;

            if (isCurryMenu) {
                Menu template = requireCurryTemplate(restaurantUsername, typeMenu);
                price = template.getPrice();
                price2 = template.getPrice2();
                price3 = template.getPrice3();
            } else {
                price = requestData.get("price") == null
                        ? 0.0
                        : Double.parseDouble(requestData.get("price").toString());
            }

            String finalImageUrl = "";
            if (requestData.containsKey("imageUrl") && requestData.get("imageUrl") != null) {
                finalImageUrl = requestData.get("imageUrl").toString();
            } else if (requestData.containsKey("imageurl") && requestData.get("imageurl") != null) {
                finalImageUrl = requestData.get("imageurl").toString();
            }

            Menu menu = Menu.builder()
                    .menuname(toStringValue(requestData.get("menuname")))
                    .description(toStringValue(requestData.get("description")))
                    .price(price)
                    .price2(price2)
                    .price3(price3)
                    .imageurl(finalImageUrl)
                    .status(toBoolean(requestData.get("status"), true))
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            Menu savedMenu = menuRepository.save(menu);

            Object groups = requestData.containsKey("optionGroups")
                    ? requestData.get("optionGroups")
                    : requestData.get("addonGroups");

            if (groups != null) {
                saveOptionGroupsFromMaps(savedMenu, groups);
            }

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนูและตัวเลือก: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    public boolean saveMenu(MenuDto requestData) {
        try {
            Restaurant restaurant = restaurantRepository.findByUsername(requestData.getUsername())
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

            TypeMenu typeMenu = resolveTypeMenu(
                    requestData.getTypeMenuId(),
                    requestData.getTypeMenuName()
            );

            boolean isCurryMenu = isCurryType(typeMenu);

            double price;
            Double price2 = null;
            Double price3 = null;

            if (isCurryMenu) {
                // ร้านข้าวราดแกงใช้ราคามาตรฐานจาก template เท่านั้น
                Menu template = requireCurryTemplate(requestData.getUsername(), typeMenu);
                price = template.getPrice();
                price2 = template.getPrice2();
                price3 = template.getPrice3();
            } else {
                price = requestData.getPrice() != null ? requestData.getPrice() : 0.0;
                price2 = requestData.getPrice2();
                price3 = requestData.getPrice3();
            }

            Menu menu = Menu.builder()
                    .menuname(requestData.getMenuname())
                    .description(requestData.getDescription())
                    .price(price)
                    .price2(price2)
                    .price3(price3)
                    .imageurl(requestData.getImageurl() != null ? requestData.getImageurl() : "")
                    .status(requestData.isStatus())
                    .restaurant(restaurant)
                    .typemenu(typeMenu)
                    .build();

            Menu savedMenu = menuRepository.save(menu);

            // เพื่อนทำเพิ่ม menu + option: รวมเข้ามาที่ saveMenu จุดเดียว
            saveOptionGroupsFromDto(savedMenu, requestData.getOptionGroups());

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการบันทึกเมนู: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการบันทึกข้อมูล: " + e.getMessage());
        }
    }

    // ==========================================================
    // Update menu + options
    // ==========================================================

    @Override
    @Transactional
    public boolean updateMenuByRestaurant(Map<String, Object> requestData) {
        try {
            Object rawMenuId = requestData.containsKey("menuId")
                    ? requestData.get("menuId")
                    : requestData.get("menuid");

            if (rawMenuId == null) {
                throw new RuntimeException("ไม่พบรหัสเมนูที่ต้องการอัปเดต");
            }

            Integer menuId = Integer.parseInt(rawMenuId.toString());
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดต"));

            if (isCurryTemplateMenu(menu)) {
                throw new RuntimeException("ไม่สามารถแก้ไขเมนูราคามาตรฐานได้");
            }

            assertNoActiveOrders(menu, "แก้ไขเมนู");

            menu.setMenuname(toStringValue(requestData.get("menuname")));
            menu.setDescription(toStringValue(requestData.get("description")));

            if (requestData.get("status") != null) {
                menu.setStatus(Boolean.parseBoolean(requestData.get("status").toString()));
            }

            if (requestData.containsKey("imageUrl") && requestData.get("imageUrl") != null) {
                menu.setImageurl(requestData.get("imageUrl").toString());
            } else if (requestData.containsKey("imageurl") && requestData.get("imageurl") != null) {
                menu.setImageurl(requestData.get("imageurl").toString());
            }

            Integer typeMenuId = toInteger(requestData.get("typeMenuId"));
            String typeMenuName = toStringValue(requestData.get("typeMenuName"));
            TypeMenu newTypeMenu = resolveTypeMenu(typeMenuId, typeMenuName);
            boolean isCurryMenu = isCurryType(newTypeMenu);

            if (isCurryMenu) {
                Menu template = requireCurryTemplate(menu.getRestaurant().getUsername(), newTypeMenu);
                menu.setPrice(template.getPrice());
                menu.setPrice2(template.getPrice2());
                menu.setPrice3(template.getPrice3());
            } else {
                if (requestData.get("price") != null) {
                    menu.setPrice(Double.parseDouble(requestData.get("price").toString()));
                }
                menu.setPrice2(requestData.get("price2") == null
                        ? null
                        : Double.parseDouble(requestData.get("price2").toString()));
                menu.setPrice3(requestData.get("price3") == null
                        ? null
                        : Double.parseDouble(requestData.get("price3").toString()));
            }

            menu.setTypemenu(newTypeMenu);
            menuRepository.save(menu);

            // รองรับการแก้ไข option groups เมื่อ Flutter ส่ง key optionGroups มา
            if (requestData.containsKey("optionGroups") && requestData.get("optionGroups") != null) {
                List<OrderDetail> oldOrderDetails = orderDetailRepository.findByMenu(menu);

                // ถ้า option เดิมเคยถูกใช้ใน order แล้ว ห้ามลบ FK เดิมทิ้ง
                if (hasHistoricalOptionUsage(oldOrderDetails)) {
                    throw new RuntimeException(
                            "ไม่สามารถแก้ไขตัวเลือกของเมนูนี้ได้ เนื่องจากเคยมีการสั่งซื้อพร้อมตัวเลือกแล้ว"
                    );
                }

                deleteOptionGroupsForMenu(menu);
                saveOptionGroupsFromMaps(menu, requestData.get("optionGroups"));
            }

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e);
            throw new RuntimeException("อัปเดตข้อมูลล้มเหลว: " + e.getMessage());
        }
    }

    // ==========================================================
    // Delete menu
    // ==========================================================

    @Override
    @Transactional
    public boolean deleteMenu(int menuId) {
        try {
            Menu menu = menuRepository.findById(menuId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการลบ"));

            if (isCurryTemplateMenu(menu)) {
                throw new RuntimeException("ไม่สามารถลบราคามาตรฐานข้าวราดแกงได้");
            }

            assertNoActiveOrders(menu, "ลบเมนู");

            List<OrderDetail> oldOrderDetails = orderDetailRepository.findByMenu(menu);

            if (hasHistoricalOptionUsage(oldOrderDetails)) {
                throw new RuntimeException(
                        "ไม่สามารถลบเมนูได้ เนื่องจากเคยมีการสั่งพร้อมตัวเลือกเสริม กรุณาปิดการขายเมนูแทน"
                );
            }

            // ปลดความสัมพันธ์จากประวัติออเดอร์เก่า ก่อนลบ Menu
            if (oldOrderDetails != null && !oldOrderDetails.isEmpty()) {
                for (OrderDetail orderDetail : oldOrderDetails) {
                    orderDetail.setMenu(null);
                }
                orderDetailRepository.saveAll(oldOrderDetails);
            }

            deleteOptionGroupsForMenu(menu);
            menuRepository.delete(menu);

            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println("เกิดข้อผิดพลาดในการลบเมนู: " + e);
            throw new RuntimeException("เกิดข้อผิดพลาดในการลบข้อมูล: " + e.getMessage());
        }
    }

    // ==========================================================
    // Legacy mapping endpoint
    // ==========================================================

    /**
     * โครงสร้างปัจจุบัน Optiongroup ผูกกับ Menu โดยตรง
     * จึงไม่ต้องมีตารางกลาง Menu-Group แล้ว
     */
    @Deprecated
    @Override
    @Transactional
    public boolean updateMenuMapping(Integer menuId, List<Integer> addonGroupIds) {
        Menu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new RuntimeException("ไม่พบเมนูที่ต้องการอัปเดตการผูกกลุ่มตัวเลือก"));

        assertNoActiveOrders(menu, "แก้ไขเมนู");

        System.out.println(
                "updateMenuMapping ถูกยกเลิกแล้ว (Optiongroup ผูกกับเมนูเดียว) menuId=" + menuId
        );
        return true;
    }

    // ==========================================================
    // Curry price template
    // ==========================================================

    @Override
    public CurryPriceDto getCurryPrice(String restaurantId, Integer typeMenuId) {
        Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

        TypeMenu curryType = resolveCurryTypeMenu(typeMenuId);

        Optional<Menu> template = findCurryTemplate(restaurant.getUsername(), curryType);
        if (template.isPresent()) {
            Menu menu = template.get();
            return new CurryPriceDto(
                    menu.getPrice(),
                    menu.getPrice2(),
                    menu.getPrice3()
            );
        }

        // Legacy data: ถ้ายังไม่มี template แต่มีเมนูข้าวราดแกงจริงอยู่
        Optional<Menu> existing = findExistingRealCurryMenu(restaurant.getUsername(), curryType);
        if (existing.isPresent()) {
            Menu menu = existing.get();
            return new CurryPriceDto(
                    menu.getPrice(),
                    menu.getPrice2(),
                    menu.getPrice3()
            );
        }

        return new CurryPriceDto(null, null, null);
    }

    @Override
    @Transactional
    public CurryPriceDto saveCurryPrice(
            String restaurantId,
            Integer typeMenuId,
            CurryPriceDto request
    ) {
        if (request == null) {
            throw new RuntimeException("ไม่พบข้อมูลราคาข้าวราดแกง");
        }

        if (request.getPrice() == null || request.getPrice() <= 0) {
            throw new RuntimeException("กรุณากำหนดราคา 1 อย่าง");
        }
        if (request.getPrice2() == null || request.getPrice2() <= 0) {
            throw new RuntimeException("กรุณากำหนดราคา 2 อย่าง");
        }
        if (request.getPrice3() == null || request.getPrice3() <= 0) {
            throw new RuntimeException("กรุณากำหนดราคา 3 อย่าง");
        }

        Restaurant restaurant = restaurantRepository.findByUsername(restaurantId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้า"));

        TypeMenu curryType = resolveCurryTypeMenu(typeMenuId);

        Optional<Menu> existingTemplate = findCurryTemplate(
                restaurant.getUsername(),
                curryType
        );

        Menu template;
        if (existingTemplate.isPresent()) {
            template = existingTemplate.get();
        } else {
            template = Menu.builder()
                    .menuname(CURRY_TEMPLATE_MENU_NAME)
                    .description("ข้อมูลราคามาตรฐานของร้าน")
                    .imageurl("")
                    .price(request.getPrice())
                    .price2(request.getPrice2())
                    .price3(request.getPrice3())
                    .status(false)
                    .restaurant(restaurant)
                    .typemenu(curryType)
                    .build();
        }

        template.setMenuname(CURRY_TEMPLATE_MENU_NAME);
        template.setDescription("ข้อมูลราคามาตรฐานของร้าน");
        template.setImageurl("");
        template.setPrice(request.getPrice());
        template.setPrice2(request.getPrice2());
        template.setPrice3(request.getPrice3());
        template.setStatus(false);
        template.setRestaurant(restaurant);
        template.setTypemenu(curryType);
        template.setCurryPriceTemplate(true);

        Menu savedTemplate = menuRepository.save(template);

        // ซิงก์ราคาล่าสุดเข้าเมนูข้าวราดแกงจริงทั้งหมด
        List<Menu> curryMenus = menuRepository
                .findByRestaurant_usernameAndTypemenu_typemenuId(
                        restaurant.getUsername(),
                        curryType.getTypemenuId()
                );

        if (curryMenus != null && !curryMenus.isEmpty()) {
            List<Menu> realMenus = new ArrayList<>();

            for (Menu menu : curryMenus) {
                if (isCurryTemplateMenu(menu)) {
                    continue;
                }

                menu.setPrice(request.getPrice());
                menu.setPrice2(request.getPrice2());
                menu.setPrice3(request.getPrice3());
                realMenus.add(menu);
            }

            if (!realMenus.isEmpty()) {
                menuRepository.saveAll(realMenus);
            }
        }

        return new CurryPriceDto(
                savedTemplate.getPrice(),
                savedTemplate.getPrice2(),
                savedTemplate.getPrice3()
        );
    }
}
