//package com.it22mjudelivery.springboot_api.v1.RunDATABase;
//
//import com.it22mjudelivery.springboot_api.v1.entities.Menu;
//import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
//import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
//import jakarta.persistence.EntityManager;
//import jakarta.persistence.PersistenceContext;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.stereotype.Component;
//import org.springframework.transaction.annotation.Transactional;
//
//@Component
//public class RunAddMenu implements CommandLineRunner {
//
//    @PersistenceContext
//    private EntityManager entityManager;
//
//    @Override
//    @Transactional
//    public void run(String... args) throws Exception {
//
//        // ดึง Restaurant username = user3333
//        Restaurant restaurant = entityManager.find(Restaurant.class, "user3333");
//        if (restaurant == null) {
//            System.out.println("❌ ไม่พบร้านค้า username = user3333");
//            return;
//        }
//
//        // เช็คว่ามีเมนูอยู่แล้วไหม
//        Long count = (Long) entityManager
//                .createQuery("SELECT COUNT(m) FROM Menu m WHERE m.restaurant.username = :username")
//                .setParameter("username", "user3333")
//                .getSingleResult();
//
//        if (count > 0) {
//            System.out.println("✅ มีเมนูอยู่แล้ว ไม่ต้อง insert ซ้ำ");
//            return;
//        }
//
//        // ดึง TypeMenu — ปรับ id ให้ตรงกับข้อมูลใน DB ของคุณ
//        TypeMenu typeMenu = entityManager.find(TypeMenu.class, 1);
//        if (typeMenu == null) {
//            System.out.println("❌ ไม่พบ TypeMenu id = 1");
//            return;
//        }
//
//        Menu menu1 = Menu.builder()
//                .menuname("ชาเย็น")
//                .description("ละมุน")
//                .imageurl("http://10.244.27.211:8081/uploads/restaurant/menu/menu004.jpg")
//                .price(40)
//                .status(true)
//                .restaurant(restaurant)
//                .typemenu(typeMenu)
//                .build();
//
//        Menu menu2 = Menu.builder()
//                .menuname("ชาเขียว")
//                .description("ใบชาจากญี่ปุ่น")
//                .imageurl("http://10.244.27.211:8081/uploads/restaurant/menu/menu005.jpg")
//                .price(45.0)
//                .status(true)
//                .restaurant(restaurant)
//                .typemenu(typeMenu)
//                .build();
//
//        Menu menu3 = Menu.builder()
//                .menuname("ลาเต้")
//                .description("ละมุนสุดๆ")
//                .imageurl("http://10.244.27.211:8081/uploads/restaurant/menu/menu006.jpg")
//                .price(45)
//                .status(true)
//                .restaurant(restaurant)
//                .typemenu(typeMenu)
//                .build();
//
//        entityManager.persist(menu1);
//        entityManager.persist(menu2);
//        entityManager.persist(menu3);
//
//        System.out.println("✅ เพิ่มเมนู 3 รายการสำเร็จ สำหรับร้าน user3333");
//    }
//}