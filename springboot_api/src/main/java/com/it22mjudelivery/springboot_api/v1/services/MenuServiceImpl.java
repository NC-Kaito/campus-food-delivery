package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.CurryPriceDto;
import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
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

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class MenuServiceImpl implements MenuService {

    private static final String CURRY_TEMPLATE_MENU_NAME = "ราคามาตรฐานข้าวราดแกง";

    private static final List<String> ACTIVE_STATUSES =
            List.of(
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
    // MENU LIST
    // ==========================================================

    @Override
    public List<Menu> getMenusByRestaurant(String username) {
        return menuRepository.findByRestaurant_username(username)
                .stream()
                .filter(m -> !isCurryTemplateMenu(m))
                .toList();
    }

    @Override
    public List<Menu> getMenusByRestaurantAndTypeMenu(
            String username,
            Integer typeMenuId
    ) {
        return menuRepository
                .findByRestaurant_usernameAndTypemenu_typemenuId(
                        username,
                        typeMenuId
                )
                .stream()
                .filter(m -> !isCurryTemplateMenu(m))
                .toList();
    }

    // ==========================================================
    // MENU STATUS
    // ==========================================================

    @Override
    public boolean updateMenuStatus(int menuId, boolean status) {
        return menuRepository.findById(menuId)
                .map(menu -> {
                    menu.setStatus(status);
                    menuRepository.save(menu);
                    return true;
                })
                .orElse(false);
    }

    // ==========================================================
    // ORDER CHECK
    // ==========================================================

    private void assertNoActiveOrders(Menu menu, String actionText) {
        if (menu.getRestaurant() == null) {
            return;
        }

        String restaurantUsername = menu.getRestaurant().getUsername();

        List<Order> activeOrders =
                orderRepository
                        .findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(
                                restaurantUsername,
                                ACTIVE_STATUSES
                        );

        if (activeOrders != null && !activeOrders.isEmpty()) {
            throw new RuntimeException(
                    "ไม่สามารถ" + actionText
                            + "ได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่"
            );
        }
    }

    // ==========================================================
    // RESOLVE TYPE MENU
    // ==========================================================

    private TypeMenu resolveTypeMenu(
            Integer typeMenuId,
            String typeMenuName
    ) {
        String name = typeMenuName == null
                ? null
                : typeMenuName.trim();

        if (typeMenuId != null && typeMenuId > 0) {
            Optional<TypeMenu> found =
                    typeMenuRepository.findById(typeMenuId);

            if (found.isPresent()) {
                return found.get();
            }
        }

        if (name != null && !name.isBlank()) {
            return typeMenuRepository
                    .findByTypemenuName(name)
                    .orElseGet(() -> {
                        TypeMenu newType = new TypeMenu();
                        newType.setTypemenuName(name);
                        return typeMenuRepository.save(newType);
                    });
        }

        throw new RuntimeException("กรุณาระบุประเภทเมนู");
    }

    private boolean isCurryType(TypeMenu typeMenu) {
        return typeMenu != null
                && typeMenu.getTypemenuName() != null
                && typeMenu.getTypemenuName().contains("ข้าวราดแกง");
    }

    // ==========================================================
    // CURRY TEMPLATE HELPERS
    // ==========================================================

    /**
     * ตรวจว่า Menu แถวนี้เป็นแถวราคามาตรฐานข้าวราดแกงหรือไม่
     * ใช้ flag จากฐานข้อมูลเป็นหลัก และรองรับข้อมูลเก่าที่ใช้ชื่อพิเศษ
     */
    private boolean isCurryTemplateMenu(Menu menu) {
        return menu != null
                && (menu.isCurryPriceTemplate()
                || CURRY_TEMPLATE_MENU_NAME.equals(menu.getMenuname()));
    }

    /**
     * หา Menu แถวราคามาตรฐานของร้าน
     * โดยใช้ชื่อแถวพิเศษ + TypeMenu เดียวกัน
     */
    private Menu findCurryTemplate(
            String restaurantUsername,
            Integer typeMenuId
    ) {
        List<Menu> menus =
                menuRepository.findByRestaurant_username(restaurantUsername);

        return menus.stream()
                .filter(this::isCurryTemplateMenu)
                .filter(m -> {
                    if (typeMenuId == null) {
                        return true;
                    }

                    return m.getTypemenu() != null
                            && Objects.equals(m.getTypemenu().getTypemenuId(), typeMenuId);
                })
                .findFirst()
                .orElse(null);
    }

    /**
     * กรณีฐานข้อมูลเดิมมีเมนูข้าวราดแกงจริงอยู่แล้ว
     * แต่ยังไม่มี template ให้ fallback ไปใช้เมนูข้าวราดแกงตัวแรก
     */
    private Menu findExistingCurryMenu(
            String restaurantUsername,
            Integer typeMenuId
    ) {
        List<Menu> menus =
                menuRepository.findByRestaurant_username(restaurantUsername);

        return menus.stream()
                .filter(m -> !isCurryTemplateMenu(m))
                .filter(m -> m.getTypemenu() != null)
                .filter(m ->
                        typeMenuId == null
                                || Objects.equals(m.getTypemenu().getTypemenuId(), typeMenuId)
                )
                .filter(m ->
                        m.getTypemenu().getTypemenuName() != null
                                && m.getTypemenu()
                                .getTypemenuName()
                                .contains("ข้าวราดแกง")
                )
                .findFirst()
                .orElse(null);
    }

    // ==========================================================
    // SAVE MENU + OPTIONS
    // ==========================================================

    @Override
    @Transactional
    public boolean saveMenuWithAddons(
            Map<String, Object> requestData
    ) {
        try {
            String restaurantId =
                    requestData.get("restaurantId") == null
                            ? null
                            : requestData.get("restaurantId").toString();

            Restaurant restaurant =
                    restaurantRepository
                            .findByUsername(restaurantId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "ไม่พบข้อมูลร้านค้า"
                                    )
                            );

            Integer typeMenuId =
                    requestData.get("typeMenuId") != null
                            ? Integer.parseInt(
                            requestData.get("typeMenuId").toString()
                    )
                            : null;

            TypeMenu typeMenu =
                    resolveTypeMenu(
                            typeMenuId,
                            requestData.get("typeMenuName") == null
                                    ? null
                                    : requestData.get("typeMenuName").toString()
                    );

            String finalImageUrl = "";

            if (requestData.get("imageUrl") != null) {
                finalImageUrl =
                        requestData.get("imageUrl").toString();
            } else if (requestData.get("imageurl") != null) {
                finalImageUrl =
                        requestData.get("imageurl").toString();
            }

            double price;
            Double price2;
            Double price3;

            if (isCurryType(typeMenu)) {
                Menu standard =
                        findCurryTemplate(
                                restaurantId,
                                typeMenu.getTypemenuId()
                        );

                if (standard == null) {
                    throw new RuntimeException(
                            "กรุณาตั้งค่าราคามาตรฐานข้าวราดแกงก่อนเพิ่มเมนู"
                    );
                }

                price = standard.getPrice();
                price2 = standard.getPrice2();
                price3 = standard.getPrice3();
            } else {
                price =
                        requestData.get("price") != null
                                ? Double.parseDouble(
                                requestData.get("price").toString()
                        )
                                : 0.0;

                price2 =
                        requestData.get("price2") != null
                                ? Double.parseDouble(
                                requestData.get("price2").toString()
                        )
                                : null;

                price3 =
                        requestData.get("price3") != null
                                ? Double.parseDouble(
                                requestData.get("price3").toString()
                        )
                                : null;
            }

            boolean status =
                    requestData.get("status") != null
                            && Boolean.parseBoolean(
                            requestData.get("status").toString()
                    );

            Menu menu =
                    Menu.builder()
                            .menuname(
                                    requestData.get("menuname") == null
                                            ? ""
                                            : requestData.get("menuname")
                                            .toString()
                            )
                            .description(
                                    requestData.get("description") == null
                                            ? ""
                                            : requestData.get("description")
                                            .toString()
                            )
                            .price(price)
                            .price2(price2)
                            .price3(price3)
                            .imageurl(finalImageUrl)
                            .status(status)
                            .restaurant(restaurant)
                            .typemenu(typeMenu)
                            .build();

            menu = menuRepository.save(menu);

            // -------------------------
            // Options
            // -------------------------
            Object rawGroups = requestData.get("addonGroups");

            if (rawGroups instanceof List<?> groupsList) {
                for (Object rawGroup : groupsList) {

                    if (!(rawGroup instanceof Map<?, ?> groupMapRaw)) {
                        continue;
                    }

                    @SuppressWarnings("unchecked")
                    Map<String, Object> groupMap =
                            (Map<String, Object>) groupMapRaw;

                    String groupName =
                            groupMap.get("addongroupname") == null
                                    ? ""
                                    : groupMap.get("addongroupname")
                                    .toString();

                    boolean required =
                            groupMap.get("is_required") != null
                                    && Boolean.parseBoolean(
                                    groupMap.get("is_required")
                                            .toString()
                            );

                    boolean multipleChoice =
                            groupMap.get("is_multiple_choice") != null
                                    && Boolean.parseBoolean(
                                    groupMap.get("is_multiple_choice")
                                            .toString()
                            );

                    Optiongroup group =
                            Optiongroup.builder()
                                    .optiongroupname(groupName)
                                    .is_required(required)
                                    .is_multiple_choice(multipleChoice)
                                    .menu(menu)
                                    .build();

                    Optiongroup savedGroup =
                            optionGroupRepository.save(group);

                    Object rawDetails =
                            groupMap.get("details");

                    if (!(rawDetails instanceof List<?> detailsList)) {
                        continue;
                    }

                    for (Object rawDetail : detailsList) {
                        if (!(rawDetail instanceof Map<?, ?> detailMapRaw)) {
                            continue;
                        }

                        @SuppressWarnings("unchecked")
                        Map<String, Object> detailMap =
                                (Map<String, Object>) detailMapRaw;

                        Object rawPrice = detailMap.get("addonprice");

                        if (rawPrice == null) {
                            continue;
                        }

                        Option option =
                                Option.builder()
                                        .optionprice(
                                                Double.parseDouble(
                                                        rawPrice.toString()
                                                )
                                        )
                                        .optiongroup(savedGroup)
                                        .build();

                        optionRepository.save(option);
                    }
                }
            }

            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(
                    "เกิดข้อผิดพลาดในการบันทึกเมนูและตัวเลือกเสริม: "
                            + e
            );

            throw new RuntimeException(
                    "เกิดข้อผิดพลาดในการบันทึกข้อมูล: "
                            + e.getMessage()
            );
        }
    }

    // ==========================================================
    // SAVE MENU
    // ==========================================================

    @Override
    @Transactional
    public boolean saveMenu(MenuDto requestData) {
        try {
            Restaurant restaurant =
                    restaurantRepository
                            .findByUsername(requestData.getUsername())
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "ไม่พบข้อมูลร้านค้า"
                                    )
                            );

            TypeMenu typeMenu =
                    resolveTypeMenu(
                            requestData.getTypeMenuId(),
                            requestData.getTypeMenuName()
                    );

            double price;
            Double price2 = null;
            Double price3 = null;

            if (isCurryType(typeMenu)) {

                Menu standard =
                        findCurryTemplate(
                                requestData.getUsername(),
                                typeMenu.getTypemenuId()
                        );

                /*
                 * ร้านข้าวราดแกงต้องตั้งราคาก่อน
                 * แล้วจึงเพิ่มเมนูจริง
                 */
                if (standard == null) {
                    throw new RuntimeException(
                            "กรุณาตั้งค่าราคามาตรฐานข้าวราดแกงก่อนเพิ่มเมนู"
                    );
                }

                price = standard.getPrice();
                price2 = standard.getPrice2();
                price3 = standard.getPrice3();

            } else {
                price =
                        requestData.getPrice() != null
                                ? requestData.getPrice()
                                : 0.0;
            }

            Menu menu =
                    Menu.builder()
                            .menuname(requestData.getMenuname())
                            .description(requestData.getDescription())
                            .price(price)
                            .price2(price2)
                            .price3(price3)
                            .imageurl(
                                    requestData.getImageurl() != null
                                            ? requestData.getImageurl()
                                            : ""
                            )
                            .status(requestData.isStatus())
                            .restaurant(restaurant)
                            .typemenu(typeMenu)
                            .build();

            menuRepository.save(menu);

            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(
                    "เกิดข้อผิดพลาดในการบันทึกเมนู: " + e
            );

            throw new RuntimeException(
                    "เกิดข้อผิดพลาดในการบันทึกข้อมูล: "
                            + e.getMessage()
            );
        }
    }

    // ==========================================================
    // UPDATE MENU
    // ==========================================================

    @Override
    @Transactional
    public boolean updateMenuByRestaurant(
            Map<String, Object> requestData
    ) {
        try {
            Object rawMenuId = requestData.get("menuId");

            if (rawMenuId == null) {
                throw new RuntimeException("ไม่พบรหัสเมนู");
            }

            Integer menuId =
                    Integer.parseInt(rawMenuId.toString());

            Menu menu =
                    menuRepository
                            .findById(menuId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "ไม่พบเมนูที่ต้องการอัปเดต"
                                    )
                            );

            // ไม่อนุญาตให้แก้แถวราคามาตรฐานเป็นเมนูอาหาร
            if (isCurryTemplateMenu(menu)) {
                throw new RuntimeException(
                        "กรุณาแก้ไขราคามาตรฐานผ่านหน้าตั้งค่าราคา"
                );
            }

            assertNoActiveOrders(menu, "แก้ไขเมนู");

            if (requestData.get("menuname") != null) {
                menu.setMenuname(
                        requestData.get("menuname").toString()
                );
            }

            if (requestData.get("description") != null) {
                menu.setDescription(
                        requestData.get("description").toString()
                );
            }

            if (requestData.get("status") != null) {
                menu.setStatus(
                        Boolean.parseBoolean(
                                requestData.get("status").toString()
                        )
                );
            }

            if (requestData.get("imageUrl") != null) {
                menu.setImageurl(
                        requestData.get("imageUrl").toString()
                );
            } else if (requestData.get("imageurl") != null) {
                menu.setImageurl(
                        requestData.get("imageurl").toString()
                );
            }

            Integer typeMenuId =
                    requestData.get("typeMenuId") != null
                            ? Integer.parseInt(
                            requestData.get("typeMenuId")
                                    .toString()
                    )
                            : null;

            TypeMenu typeMenu =
                    resolveTypeMenu(
                            typeMenuId,
                            requestData.get("typeMenuName") == null
                                    ? null
                                    : requestData.get("typeMenuName")
                                    .toString()
                    );

            menu.setTypemenu(typeMenu);

            // เมนูข้าวราดแกงต้องใช้ราคามาตรฐานจาก template
            if (isCurryType(typeMenu)) {
                Menu standard =
                        findCurryTemplate(
                                menu.getRestaurant().getUsername(),
                                typeMenu.getTypemenuId()
                        );

                if (standard == null) {
                    throw new RuntimeException(
                            "กรุณาตั้งค่าราคามาตรฐานข้าวราดแกงก่อนเพิ่มหรือแก้ไขเมนู"
                    );
                }

                menu.setPrice(standard.getPrice());
                menu.setPrice2(standard.getPrice2());
                menu.setPrice3(standard.getPrice3());

            } else if (requestData.get("price") != null) {
                menu.setPrice(
                        Double.parseDouble(
                                requestData.get("price").toString()
                        )
                );

                if (requestData.get("price2") != null) {
                    menu.setPrice2(
                            Double.parseDouble(
                                    requestData.get("price2").toString()
                            )
                    );
                }

                if (requestData.get("price3") != null) {
                    menu.setPrice3(
                            Double.parseDouble(
                                    requestData.get("price3").toString()
                            )
                    );
                }
            }

            menuRepository.save(menu);
            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(
                    "เกิดข้อผิดพลาดในการอัปเดตเมนู: " + e
            );

            throw new RuntimeException(
                    "อัปเดตข้อมูลล้มเหลว: "
                            + e.getMessage()
            );
        }
    }

    // ==========================================================
    // DELETE MENU
    // ==========================================================

    @Override
    @Transactional
    public boolean deleteMenu(int menuId) {
        try {
            Menu menu =
                    menuRepository
                            .findById(menuId)
                            .orElseThrow(() ->
                                    new RuntimeException(
                                            "ไม่พบเมนูที่ต้องการลบ"
                                    )
                            );

            if (isCurryTemplateMenu(menu)) {
                throw new RuntimeException(
                        "ไม่สามารถลบข้อมูลราคามาตรฐานข้าวราดแกงได้"
                );
            }

            assertNoActiveOrders(menu, "ลบเมนู");

            List<OrderDetail> oldOrderDetails =
                    orderDetailRepository.findByMenu(menu);

            if (oldOrderDetails != null) {
                for (OrderDetail od : oldOrderDetails) {
                    if (od.getOrderDetailOptions() != null
                            && !od.getOrderDetailOptions().isEmpty()) {

                        throw new RuntimeException(
                                "ไม่สามารถลบเมนูได้ เนื่องจากเคยมีการสั่งพร้อมตัวเลือกเสริม กรุณาปิดการขายเมนูแทน"
                        );
                    }
                }

                for (OrderDetail od : oldOrderDetails) {
                    od.setMenu(null);
                }

                orderDetailRepository.saveAll(oldOrderDetails);
            }

            List<Optiongroup> groups =
                    optionGroupRepository.findByMenu(menu);

            for (Optiongroup group : groups) {
                optionRepository.deleteAll(
                        optionRepository.findByOptiongroup(group)
                );
            }

            optionGroupRepository.deleteAll(groups);

            menuRepository.delete(menu);

            return true;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.out.println(e);

            throw new RuntimeException(
                    "เกิดข้อผิดพลาดในการลบข้อมูล: "
                            + e.getMessage()
            );
        }
    }

    // ==========================================================
    // DEPRECATED MAPPING
    // ==========================================================

    @Deprecated
    @Override
    @Transactional
    public boolean updateMenuMapping(
            Integer menuId,
            List<Integer> addonGroupIds
    ) {
        Menu menu =
                menuRepository
                        .findById(menuId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "ไม่พบเมนูที่ต้องการอัปเดตการผูกกลุ่มตัวเลือก"
                                )
                        );

        assertNoActiveOrders(menu, "แก้ไขเมนู");
        return true;
    }

    // ==========================================================
    // GET CURRY PRICE
    // ==========================================================

    @Override
    public CurryPriceDto getCurryPrice(
            String restaurantId,
            Integer typeMenuId
    ) {
        if (restaurantId == null || restaurantId.isBlank()) {
            return new CurryPriceDto(null, null, null);
        }

        Menu target =
                findCurryTemplate(
                        restaurantId,
                        typeMenuId
                );

        // รองรับข้อมูลเก่าที่มีเมนูจริง แต่ยังไม่มี template
        if (target == null) {
            target =
                    findExistingCurryMenu(
                            restaurantId,
                            typeMenuId
                    );
        }

        if (target == null) {
            return new CurryPriceDto(null, null, null);
        }

        return new CurryPriceDto(
                target.getPrice(),
                target.getPrice2(),
                target.getPrice3()
        );
    }

    // ==========================================================
    // SAVE / UPDATE CURRY PRICE
    // ==========================================================

    @Override
    @Transactional
    public CurryPriceDto saveCurryPrice(
            String restaurantId,
            Integer typeMenuId,
            CurryPriceDto request
    ) {
        if (request == null) {
            throw new RuntimeException(
                    "ไม่พบข้อมูลราคาข้าวราดแกง"
            );
        }

        if (request.getPrice() == null
                || request.getPrice() <= 0) {
            throw new RuntimeException(
                    "กรุณากำหนดราคา 1 อย่าง"
            );
        }

        if (request.getPrice2() == null
                || request.getPrice2() <= 0) {
            throw new RuntimeException(
                    "กรุณากำหนดราคา 2 อย่าง"
            );
        }

        if (request.getPrice3() == null
                || request.getPrice3() <= 0) {
            throw new RuntimeException(
                    "กรุณากำหนดราคา 3 อย่าง"
            );
        }

        Restaurant restaurant =
                restaurantRepository
                        .findByUsername(restaurantId)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "ไม่พบข้อมูลร้านค้า"
                                )
                        );

        /*
         * ถ้า Flutter ส่ง typeMenuId มาแล้ว ใช้ ID นั้น
         * ถ้าไม่ส่ง ให้หา "ข้าวราดแกง" จากชื่อ
         */
        TypeMenu typeMenu =
                resolveTypeMenu(
                        typeMenuId,
                        "ข้าวราดแกง"
                );

        if (!isCurryType(typeMenu)) {
            throw new RuntimeException(
                    "ประเภทเมนูที่เลือกไม่ใช่ข้าวราดแกง"
            );
        }

        /*
         * สำคัญ:
         * ใช้ตาราง menu เดิมเท่านั้น
         * โดยสร้าง/อัปเดตแถว template
         */
        Menu template =
                findCurryTemplate(
                        restaurantId,
                        typeMenu.getTypemenuId()
                );

        if (template == null) {
            template =
                    Menu.builder()
                            .menuname(CURRY_TEMPLATE_MENU_NAME)
                            .description(
                                    "ข้อมูลราคามาตรฐานของร้าน"
                            )
                            .imageurl("")
                            .price(request.getPrice())
                            .price2(request.getPrice2())
                            .price3(request.getPrice3())
                            .status(false)
                            .curryPriceTemplate(true)
                            .restaurant(restaurant)
                            .typemenu(typeMenu)
                            .build();
        } else {
            template.setPrice(request.getPrice());
            template.setPrice2(request.getPrice2());
            template.setPrice3(request.getPrice3());
            template.setStatus(false);
            template.setCurryPriceTemplate(true);
            template.setRestaurant(restaurant);
            template.setTypemenu(typeMenu);
        }

        menuRepository.save(template);

        /*
         * ซิงก์ราคาให้เมนูข้าวราดแกงจริงที่มีอยู่แล้ว
         * โดยไม่แตะเมนูหมวดอื่น และไม่แตะแถว template ซ้ำ
         */
        List<Menu> existingMenus =
                menuRepository.findByRestaurant_username(
                        restaurantId
                );

        if (existingMenus != null) {
            for (Menu menu : existingMenus) {
                if (isCurryTemplateMenu(menu)) {
                    continue;
                }

                if (menu.getTypemenu() == null) {
                    continue;
                }

                if (menu.getTypemenu().getTypemenuId()
                        != typeMenu.getTypemenuId()) {
                    continue;
                }

                if (!isCurryType(menu.getTypemenu())) {
                    continue;
                }

                menu.setPrice(request.getPrice());
                menu.setPrice2(request.getPrice2());
                menu.setPrice3(request.getPrice3());
            }

            menuRepository.saveAll(existingMenus);
        }

        return new CurryPriceDto(
                request.getPrice(),
                request.getPrice2(),
                request.getPrice3()
        );
    }
}
