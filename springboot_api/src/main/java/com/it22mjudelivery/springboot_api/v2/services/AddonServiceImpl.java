package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.dtos.AddonGroupRequestDTO;
import com.it22mjudelivery.springboot_api.v2.entities.*;
import com.it22mjudelivery.springboot_api.v2.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
@RequiredArgsConstructor
public class AddonServiceImpl implements AddonService {

    private final RestaurantRepository restaurantRepository;
    private final MenuaddongroupRepository menuaddongroupRepository;
    private final AddonmenuRepository addonmenuRepository;
    private final MenuaddondetailRepository menuaddondetailRepository;

    // 🎯 1. ประกาศใช้ OrderRepository
    private final OrderRepository orderRepository;

    @Transactional
    public boolean createAddonGroupTemplate(AddonGroupRequestDTO request) {
        try {
            Restaurant restaurant = restaurantRepository.findById(request.getRestaurantUsername())
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้าในระบบ"));

            Menuaddongroup group = Menuaddongroup.builder()
                    .addongroupname(request.getAddongroupname())
                    .is_multiple_choice(request.is_multiple_choice())
                    .status(request.isStatus())
                    .username(restaurant)
                    .build();

            Menuaddongroup savedGroup = menuaddongroupRepository.save(group);

            if (request.getDetails() != null && !request.getDetails().isEmpty()) {
                for (AddonGroupRequestDTO.AddonDetailDTO detailDTO : request.getDetails()) {

                    Optional<Addonmenu> existingAddon = addonmenuRepository.findByAddonname(detailDTO.getAddonname());

                    Addonmenu addonmenu;
                    if (existingAddon.isPresent()) {
                        addonmenu = existingAddon.get();
                    } else {
                        addonmenu = Addonmenu.builder()
                                .addonname(detailDTO.getAddonname())
                                .build();
                        addonmenu = addonmenuRepository.save(addonmenu);
                    }

                    Menuaddondetail detail = Menuaddondetail.builder()
                            .addonprice(detailDTO.getAddonprice())
                            .status(detailDTO.isStatus())
                            .allowqtystatus(detailDTO.isAllowqtystatus())
                            .menuaddongroup(savedGroup)
                            .addonmenu(addonmenu)
                            .build();

                    menuaddondetailRepository.save(detail);
                }
            }
            return true;
        } catch (Exception e) {
            System.err.println("เกิดข้อผิดพลาดในการสร้างกลุ่มท็อปปิ้ง: " + e.getMessage());
            throw new RuntimeException("สร้างกลุ่มท็อปปิ้งล้มเหลว: " + e.getMessage());
        }
    }

    @Transactional
    public boolean updateAddonGroupTemplate(AddonGroupRequestDTO request) {
        try {
            if (request.getAddongroupid() == null) {
                throw new RuntimeException("ไม่พบรหัสกลุ่มตัวเลือกที่ต้องการแก้ไข");
            }

            // 🎯 2. เช็กสถานะออเดอร์ก่อนทำการแก้ไข Add-on
            String restaurantUsername = request.getRestaurantUsername();
            List< String > activeStatuses = List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            List<Order> activeOrders = orderRepository.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, activeStatuses);

            if (activeOrders != null && !activeOrders.isEmpty()) {
                throw new RuntimeException("ไม่สามารถแก้ไขตัวเลือกเสริมได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
            }

            Menuaddongroup existingGroup = menuaddongroupRepository.findById(request.getAddongroupid())
                    .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริมที่ต้องการแก้ไข"));

            if (!existingGroup.getUsername().getUsername().equals(request.getRestaurantUsername())) {
                throw new RuntimeException("ไม่มีสิทธิ์แก้ไขกลุ่มตัวเลือกนี้");
            }

            existingGroup.setAddongroupname(request.getAddongroupname());
            existingGroup.set_multiple_choice(request.is_multiple_choice());
            existingGroup.setStatus(request.isStatus());

            Menuaddongroup savedGroup = menuaddongroupRepository.save(existingGroup);

            List<Menuaddondetail> currentDetails =
                    menuaddondetailRepository.findByMenuaddongroup(savedGroup);

            Map< Integer, Menuaddondetail> currentDetailMap = new HashMap<>();
            for (Menuaddondetail d : currentDetails) {
                currentDetailMap.put(d.getAddondetailid(), d);
            }

            Set< Integer > keepIds = new HashSet<>();

            if (request.getDetails() != null) {
                for (AddonGroupRequestDTO.AddonDetailDTO detailDTO : request.getDetails()) {

                    Optional<Addonmenu> existingAddon =
                            addonmenuRepository.findByAddonname(detailDTO.getAddonname());
                    Addonmenu addonmenu = existingAddon.orElseGet(() ->
                            addonmenuRepository.save(
                                    Addonmenu.builder().addonname(detailDTO.getAddonname()).build()
                            )
                    );

                    if (detailDTO.getAddondetailId() != null
                            && currentDetailMap.containsKey(detailDTO.getAddondetailId())) {
                        Menuaddondetail existingDetail = currentDetailMap.get(detailDTO.getAddondetailId());
                        existingDetail.setAddonprice(detailDTO.getAddonprice());
                        existingDetail.setStatus(detailDTO.isStatus());
                        existingDetail.setAddonmenu(addonmenu);
                        existingDetail.setAllowqtystatus(detailDTO.isAllowqtystatus());

                        menuaddondetailRepository.save(existingDetail);

                        keepIds.add(detailDTO.getAddondetailId());
                    } else {
                        Menuaddondetail newDetail = Menuaddondetail.builder()
                                .addonprice(detailDTO.getAddonprice())
                                .status(detailDTO.isStatus())
                                .allowqtystatus(detailDTO.isAllowqtystatus())
                                .menuaddongroup(savedGroup)
                                .addonmenu(addonmenu)
                                .build();
                        Menuaddondetail saved = menuaddondetailRepository.save(newDetail);

                        keepIds.add(saved.getAddondetailid());
                    }
                }
            }

            for (Menuaddondetail d : currentDetails) {
                if (!keepIds.contains(d.getAddondetailid())) {
                    d.setMenuaddongroup(null); // ตัดหางปล่อยวัดเช่นเดียวกัน
                    menuaddondetailRepository.save(d); // บันทึกแทนการสั่งลบทิ้ง
                }
            }

            return true;
        } catch (RuntimeException e) {
            throw e; // โยน RuntimeException ออกไปให้ Controller ทันที
        } catch (Exception e) {
            System.err.println("เกิดข้อผิดพลาดในการแก้ไขกลุ่มท็อปปิ้ง: " + e.getMessage());
            throw new RuntimeException("แก้ไขกลุ่มท็อปปิ้งล้มเหลว: " + e.getMessage());
        }
    }

    public List<Addonmenu> searchAddonByName(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return List.of();
        }
        return addonmenuRepository.searchByKeyword(keyword.trim(), PageRequest.of(0, 5));
    }

    @Transactional
    public boolean deleteAddonGroup(Integer groupId) {
        try {
            Menuaddongroup group = menuaddongroupRepository.findById(groupId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริมที่ต้องการลบ"));

            // 1. เช็กสถานะออเดอร์ก่อนทำการลบ Add-on
            String restaurantUsername = group.getUsername().getUsername();
            List< String > activeStatuses = List.of("WaitingRider", "WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            List<Order> activeOrders = orderRepository.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(restaurantUsername, activeStatuses);

            if (activeOrders != null && !activeOrders.isEmpty()) {
                throw new RuntimeException("ไม่สามารถลบตัวเลือกเสริมได้ เนื่องจากร้านมีออเดอร์ที่กำลังดำเนินการอยู่");
            }

            // 2. ลบความสัมพันธ์กับเมนูอาหารหลัก
            menuaddongroupRepository.removeAllMenuLinks(groupId);

            // 🎯 3. ตัดหางปล่อยวัด Addon ลูก (เปลี่ยนจากการใช้ deleteAll)
            List<Menuaddondetail> details = menuaddondetailRepository.findByMenuaddongroup(group);
            if (details != null && !details.isEmpty()) {
                for (Menuaddondetail detail : details) {
                    detail.setMenuaddongroup(null); // ทำให้ตัวลูกไม่มีกลุ่ม (เพื่อรักษาประวัติใบเสร็จไว้)
                }
                menuaddondetailRepository.saveAll(details); // บันทึกการเปลี่ยนแปลง
            }

            // 🎯 4. ลบแค่กลุ่มแม่ทิ้ง
            menuaddongroupRepository.delete(group);
            return true;
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("เกิดข้อผิดพลาดในการลบกลุ่มท็อปปิ้ง: " + e.getMessage());
            throw new RuntimeException("ลบกลุ่มท็อปปิ้งล้มเหลว: " + e.getMessage());
        }
    }   }