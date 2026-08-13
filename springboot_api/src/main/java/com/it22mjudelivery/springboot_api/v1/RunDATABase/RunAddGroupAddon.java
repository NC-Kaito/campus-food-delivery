//package com.it22mjudelivery.springboot_api.v1.RunDATABase;
//
//import com.it22mjudelivery.springboot_api.v1.entities.*;
//import com.it22mjudelivery.springboot_api.v1.repositories.*;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.stereotype.Component;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.util.HashSet;
//
//@Component
//public class RunAddGroupAddon implements CommandLineRunner {
//
//    @Autowired
//    private TypeMenuRepository typeMenuRepository;
//    @Autowired
//    private MenuaddongroupRepository menuaddongroupRepository;
//    @Autowired
//    private RestaurantRepository restaurantRepository;
//    @Autowired
//    private AddonmenuRepository addonmenuRepository;
//    @Autowired
//    private MenuaddondetailRepository menuaddondetailRepository;
//
//    @Override
//    @Transactional
//    public void run(String... args) throws Exception {
//        // เอาเงื่อนไขตรวจเช็กข้อมูลเก่าออก เพื่อบังคับ Insert ใหม่ทุกครั้งที่รัน
//        System.out.println("====== 🚀 เริ่มบังคับจำลองข้อมูล Template Add-on แถวใหม่ ======");
//
//        try {
//            Restaurant mockRestaurant = restaurantRepository.findAll().stream().findFirst().orElse(null);
//            if (mockRestaurant == null) {
//                System.out.println("❌ ไม่สามารถ Mock ได้: ไม่มีข้อมูลร้านค้าในตาราง Restaurant");
//                return;
//            }
//
//            // ==========================================
//            // 🍹 ผูกกับ ID 2: เครื่องดื่ม
//            // ==========================================
//            Menuaddongroup sizeGroup = createGroup("ขนาดแก้ว", false, mockRestaurant);
//            createDetail("Size S", 0, sizeGroup);
//            createDetail("Size M", 10, sizeGroup);
//            createDetail("Size L", 20, sizeGroup);
//
//            Menuaddongroup sweetGroup = createGroup("ระดับความหวาน", false, mockRestaurant);
//            createDetail("ไม่หวาน (0%)", 0, sweetGroup);
//            createDetail("หวานน้อย (50%)", 0, sweetGroup);
//            createDetail("หวานปกติ (100%)", 0, sweetGroup);
//
//            bindToTypeMenu(2, sizeGroup, sweetGroup);
//
//            // ==========================================
//            // 🍜 ผูกกับ ID 4: เส้น และ ID 7: ก๋วยเตี๋ยว
//            // ==========================================
//            Menuaddongroup noodleGroup = createGroup("ประเภทเส้น", false, mockRestaurant);
//            createDetail("เส้นเล็ก", 0, noodleGroup);
//            createDetail("เส้นใหญ่", 0, noodleGroup);
//            createDetail("บะหมี่", 0, noodleGroup);
//            createDetail("หมี่ขาว", 0, noodleGroup);
//
//            Menuaddongroup soupGroup = createGroup("ประเภทน้ำ", false, mockRestaurant);
//            createDetail("น้ำใส", 0, soupGroup);
//            createDetail("ต้มยำ", 0, soupGroup);
//            createDetail("น้ำตก", 0, soupGroup);
//            createDetail("แห้ง", 0, soupGroup);
//
//            bindToTypeMenu(4, noodleGroup, soupGroup);
//            bindToTypeMenu(7, noodleGroup, soupGroup);
//
//            // ==========================================
//            // 🍛 ผูกกับ ID 1: อาหารตามสั่ง
//            // ==========================================
//            Menuaddongroup portionGroup = createGroup("ปริมาณ", false, mockRestaurant);
//            createDetail("ธรรมดา", 0, portionGroup);
//            createDetail("พิเศษ", 10, portionGroup);
//
//            Menuaddongroup eggGroup = createGroup("เพิ่มไข่", true, mockRestaurant); // is_multiple = true
//            createDetail("ไข่ดาว", 10, eggGroup);
//            createDetail("ไข่เจียว", 12, eggGroup);
//            createDetail("ไข่ต้ม", 10, eggGroup);
//
//            Menuaddongroup spicyGroup = createGroup("ระดับความเผ็ด", false, mockRestaurant);
//            createDetail("เผ็ดปกติ", 0, spicyGroup);
//            createDetail("เผ็ดน้อย", 0, spicyGroup);
//            createDetail("ไม่ใส่พริก", 0, spicyGroup);
//
//            bindToTypeMenu(1, portionGroup, eggGroup, spicyGroup);
//
//            System.out.println("✅ Mock Data เพิ่มแถวใหม่ สำเร็จครบทุกหมวดหมู่!");
//
//        } catch (Exception e) {
//            System.out.println("❌ เกิดข้อผิดพลาดในการ Mock Data: " + e.getMessage());
//            e.printStackTrace();
//        }
//    }
//
//    // -------------------------------------------------------------
//    // 🛠️ Helper Methods
//    // -------------------------------------------------------------
//
//    private Menuaddongroup createGroup(String name, boolean isMultiple, Restaurant rest) {
//        Menuaddongroup group = Menuaddongroup.builder()
//                .addongroupname(name)
//                .is_multiple_choice(isMultiple)
//                .status(true)
//                .username(rest)
//                .build();
//        return menuaddongroupRepository.save(group);
//    }
//
//    private void createDetail(String name, double price, Menuaddongroup group) {
//        Addonmenu addonMaster = Addonmenu.builder()
//                .addonname(name)
//                .build();
//        addonMaster = addonmenuRepository.save(addonMaster);
//
//        Menuaddondetail detail = Menuaddondetail.builder()
//                .addonprice(price)
//                .status(true)
//                .allowqtystatus(false)
//                .menuaddongroup(group)
//                .addonmenu(addonMaster)
//                .build();
//        menuaddondetailRepository.save(detail);
//    }
//
//    private void bindToTypeMenu(int typeMenuId, Menuaddongroup... groups) {
//        TypeMenu typeMenu = typeMenuRepository.findById(typeMenuId).orElse(null);
//        if (typeMenu != null) {
//            if (typeMenu.getDefaultAddonGroups() == null) {
//                typeMenu.setDefaultAddonGroups(new HashSet<>());
//            }
//            for (Menuaddongroup group : groups) {
//                typeMenu.getDefaultAddonGroups().add(group);
//            }
//            typeMenuRepository.save(typeMenu);
//        } else {
//            System.out.println("⚠️ คำเตือน: ไม่พบหมวดหมู่ TypeMenu ID: " + typeMenuId);
//        }
//    }
//}