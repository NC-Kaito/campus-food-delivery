//package com.it22mjudelivery.springboot_api.v1.RunDATABase;
//
//import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
//import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
//import lombok.RequiredArgsConstructor;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.stereotype.Component;
//
//import java.util.Arrays;
//import java.util.List;
//
//@Component
//@RequiredArgsConstructor
//public class RunAddTypeRestaurant implements CommandLineRunner {
//
//    private final TypeRestaurantRepository typeRepository;
//
//    @Override
//    public void run(String... args) throws Exception {
//        // เช็คก่อนว่ามีข้อมูลหรือยัง เพื่อป้องกันการเพิ่มข้อมูลซ้ำทุกครั้งที่รันแอป
//        if (typeRepository.count() == 0) {
//            List<TypeRestaurant> types = Arrays.asList(
//                    TypeRestaurant.builder().typerestaurantName("อาหารตามสั่ง").build(),
//                    TypeRestaurant.builder().typerestaurantName("เส้น").build(),
//                    TypeRestaurant.builder().typerestaurantName("เครื่องดื่ม").build(),
//                    TypeRestaurant.builder().typerestaurantName("ของหวาน").build(),
//                    TypeRestaurant.builder().typerestaurantName("อาหารฮาลาล").build(),
//                    TypeRestaurant.builder().typerestaurantName("ผลไม้").build()
//            );
//
//            typeRepository.saveAll(types);
//            System.out.println("✅ เพิ่มข้อมูลประเภทร้านค้าเริ่มต้นเรียบร้อยแล้ว!");
//        }
//    }
//}