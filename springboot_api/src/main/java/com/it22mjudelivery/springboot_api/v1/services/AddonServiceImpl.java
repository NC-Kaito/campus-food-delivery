package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddonGroupRequestDTO;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class AddonServiceImpl implements AddonService {

    private final RestaurantRepository restaurantRepository;
    private final MenuaddongroupRepository menuaddongroupRepository;
    private final AddonmenuRepository addonmenuRepository;
    private final MenuaddondetailRepository menuaddondetailRepository;

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

            Menuaddongroup existingGroup = menuaddongroupRepository.findById(request.getAddongroupid())
                    .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริมที่ต้องการแก้ไข"));

            if (!existingGroup.getUsername().getUsername().equals(request.getRestaurantUsername())) {
                throw new RuntimeException("ไม่มีสิทธิ์แก้ไขกลุ่มตัวเลือกนี้");
            }

            // ── 1. อัปเดตข้อมูลของกลุ่ม ──
            existingGroup.setAddongroupname(request.getAddongroupname());
            existingGroup.set_multiple_choice(request.is_multiple_choice());
            existingGroup.setStatus(request.isStatus());

            Menuaddongroup savedGroup = menuaddongroupRepository.save(existingGroup);

            // ── 2. ดึงแถว detail เดิมทั้งหมดของกลุ่มนี้มาก่อน ──
            List<Menuaddondetail> currentDetails =
                    menuaddondetailRepository.findByMenuaddongroup(savedGroup);

            Map<Integer, Menuaddondetail> currentDetailMap = new HashMap<>();
            for (Menuaddondetail d : currentDetails) {
                currentDetailMap.put(d.getAddondetailid(), d); // ← เช็คชื่อ getter ตาม entity จริง
            }

            Set<Integer> keepIds = new HashSet<>();

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
                        // ── UPDATE แถวเดิม ──
                        Menuaddondetail existingDetail = currentDetailMap.get(detailDTO.getAddondetailId());
                        existingDetail.setAddonprice(detailDTO.getAddonprice());
                        existingDetail.setStatus(detailDTO.isStatus());
                        existingDetail.setAddonmenu(addonmenu);

                        // 🎯 [แก้ไข] เพิ่มบรรทัดนี้ลงไปครับ ไม่งั้น allowqtystatus จะไม่ยอมอัปเดต
                        existingDetail.setAllowqtystatus(detailDTO.isAllowqtystatus());

                        menuaddondetailRepository.save(existingDetail);

                        keepIds.add(detailDTO.getAddondetailId());
                    } else {
                        // ── INSERT แถวใหม่ ──
                        Menuaddondetail newDetail = Menuaddondetail.builder()
                                .addonprice(detailDTO.getAddonprice())
                                .status(detailDTO.isStatus())
                                .allowqtystatus(detailDTO.isAllowqtystatus()) // 🎯 [แก้ไข] เช็คตรงสร้างใหม่ด้วยว่ามีบรรทัดนี้แล้ว
                                .menuaddongroup(savedGroup)
                                .addonmenu(addonmenu)
                                .build();
                        Menuaddondetail saved = menuaddondetailRepository.save(newDetail);

                        keepIds.add(saved.getAddondetailid());
                    }
                }
            }

            // ── 3. ลบเฉพาะแถวที่ผู้ใช้กด "ลบ" ออกจากฟอร์มจริงๆ ──
            for (Menuaddondetail d : currentDetails) {
                if (!keepIds.contains(d.getAddondetailid())) {
                    menuaddondetailRepository.delete(d);
                }
            }

            return true;
        } catch (Exception e) {
            System.err.println("เกิดข้อผิดพลาดในการแก้ไขกลุ่มท็อปปิ้ง: " + e.getMessage());
            throw new RuntimeException("แก้ไขกลุ่มท็อปปิ้งล้มเหลว: " + e.getMessage());
        }
    }

    public List<Addonmenu> searchAddonByName(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return List.of();
        }
        // จำกัดผลลัพธ์แค่ 5 รายการ ด้วย PageRequest.of(0, 5)
        return addonmenuRepository.searchByKeyword(keyword.trim(), PageRequest.of(0, 5));
    }

    @Transactional
    public boolean deleteAddonGroup(Integer groupId) {
        try {
            Menuaddongroup group = menuaddongroupRepository.findById(groupId)
                    .orElseThrow(() -> new RuntimeException("ไม่พบกลุ่มตัวเลือกเสริมที่ต้องการลบ"));

            // 🎯 1. ลบความสัมพันธ์ที่ผูกกับเมนูอาหารออกก่อน (ปลดล็อก Foreign Key)
            menuaddongroupRepository.removeAllMenuLinks(groupId);

            // 2. ลบ detail ลูกทั้งหมดก่อน (กัน foreign key constraint)
            List<Menuaddondetail> details = menuaddondetailRepository.findByMenuaddongroup(group);
            menuaddondetailRepository.deleteAll(details);

            // 3. ลบกลุ่มตัวเลือกหลักได้เลย
            menuaddongroupRepository.delete(group);
            return true;
        } catch (Exception e) {
            System.err.println("เกิดข้อผิดพลาดในการลบกลุ่มท็อปปิ้ง: " + e.getMessage());
            throw new RuntimeException("ลบกลุ่มท็อปปิ้งล้มเหลว: " + e.getMessage());
        }
    }
}