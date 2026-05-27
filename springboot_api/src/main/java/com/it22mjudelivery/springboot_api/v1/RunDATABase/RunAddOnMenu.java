//package com.it22mjudelivery.springboot_api.v1.RunDATABase;
//
//import com.it22mjudelivery.springboot_api.v1.entities.*;
//import com.it22mjudelivery.springboot_api.v1.repositories.AddonmenuRepository;
//import com.it22mjudelivery.springboot_api.v1.repositories.MenuRepository;
//import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddondetailRepository;
//import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddongroupRepository;
//import jakarta.persistence.EntityManager;
//import jakarta.persistence.PersistenceContext;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.stereotype.Component;
//import org.springframework.transaction.annotation.Transactional;
//
//import java.util.List;
//
//@Component
//public class RunAddOnMenu implements CommandLineRunner {
//
//    @Autowired
//    private MenuRepository menuRepository;
//
//    @Autowired
//    private AddonmenuRepository addonmenuRepository;
//
//    @Autowired
//    private MenuaddongroupRepository menuaddongroupRepository;
//
//    @Autowired
//    private MenuaddondetailRepository menuaddondetailRepository;
//
//    @PersistenceContext
//    private EntityManager entityManager;
//
//    @Override
//    @Transactional
//    public void run(String... args) throws Exception {
//
//    String restaurantTarget = "user9999";
//    List<Menu> menus = menuRepository.findByRestaurant_username(restaurantTarget);
//    System.out.println("Menus = "+ menus.size());
//
//
//    if(!menus.isEmpty()){
//        Addonmenu addonmenu1 = Addonmenu.builder()
//                .addonname("พิเศษ")
//                .build();
//
//        Addonmenu addonmenu2 = Addonmenu.builder()
//                .addonname("ธรรมดา")
//                .build();
////        Addonmenu addonmenu3 = Addonmenu.builder()
////                .addonname("ไก่กรอบ")
////                .build();
//
//        Menuaddongroup menuaddongroup1 = Menuaddongroup.builder()
//                .addongroupname("ธรรมดาพิเศษ")
//                .maxselect(1)
//                .isRequired(true)
//                .menu(menus.get(0))
//                .build();
//
//        Menuaddondetail menuaddondetail1 = Menuaddondetail.builder()
//                .addonprice(10)
//                .menuaddongroup(menuaddongroup1)
//                .addonmenu(addonmenu1)
//                .build();
//
//        Menuaddondetail menuaddondetail2 = Menuaddondetail.builder()
//                .addonprice(10)
//                .menuaddongroup(menuaddongroup1)
//                .addonmenu(addonmenu2)
//                .build();
//
////        Menuaddondetail menuaddondetail3 = Menuaddondetail.builder()
////                .addonprice(10)
////                .menuaddongroup(menuaddongroup1)
////                .addonmenu(addonmenu3)
////                .build();
//
//        addonmenuRepository.saveAll(List.of(addonmenu1, addonmenu2));
//        menuaddongroupRepository.save(menuaddongroup1);
//        menuaddondetailRepository.saveAll(List.of(menuaddondetail1, menuaddondetail2));
//
//        System.out.println("✅ เพิ่มกลุ่มข้อมูลเมนูเสริม 'เพิ่มไข่' พร้อมรายการตัวเลือก 3 ชนิดสำเร็จ!");
//
//    }else {
//        System.out.println("❌ ไม่สามารถเพิ่มกลุ่ม Add-on ได้เนื่องจากไม่พบเมนูของร้านนี้");
//    }
//
//}
//}
