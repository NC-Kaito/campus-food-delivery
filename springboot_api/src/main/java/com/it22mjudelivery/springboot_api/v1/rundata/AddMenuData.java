package com.it22mjudelivery.springboot_api.v1.rundata;

import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

@Component
@RequiredArgsConstructor
public class AddMenuData implements CommandLineRunner {

    private final TypeMenuRepository typeMenuRepository;
    private final MenuRepository menuRepository;
    private final RestaurantRepository restaurantRepository;

    @Override
    public void run(String... args) throws Exception {
        // 1. เพิ่มประเภทอาหาร (ถ้ายังไม่มี)
        if (typeMenuRepository.count() == 0) {
            List<TypeMenu> types = Arrays.asList(
                    TypeMenu.builder().typemenuName("อาหารจานเดียว").build(),
                    TypeMenu.builder().typemenuName("เครื่องดื่ม").build(),
                    TypeMenu.builder().typemenuName("ทานเล่น").build()
            );
            typeMenuRepository.saveAll(types);
        }

        // 2. เพิ่มเมนูอาหาร (ดึงร้านค้าแรกใน DB มาเป็นเจ้าของเมนู)
        if (menuRepository.count() == 0) {
            List<Restaurant> restaurants = restaurantRepository.findAll();
            List<TypeMenu> typeMenus = typeMenuRepository.findAll();
            String target = "user201";
            if (!restaurants.isEmpty() && !typeMenus.isEmpty()) {
                Restaurant targetStore = restaurantRepository.findByUsername(target).orElseThrow();
                TypeMenu mainCourse = typeMenus.get(0);      // ประเภทอาหารจานเดียว
                TypeMenu drink = typeMenus.get(1);            // ประเภทเครื่องดื่ม

                List<Menu> menus = Arrays.asList(
                        Menu.builder()
                                .menuname("ข้าวกะเพราหมูสับ")
                                .description("รสชาติจัดจ้าน สไตล์ไทยแท้")
                                .imageurl("1.jpg")
                                .price(50.0)
                                .status(true)
                                .restaurant(targetStore)
                                .typemenu(mainCourse)
                                .build(),
                        Menu.builder()
                                .menuname("ข้าวผัดไข่")
                                .description("ข้าวหอมมะลิผัดไข่ร้อนๆ")
                                .imageurl("2.jpg")
                                .price(45.0)
                                .status(true)
                                .restaurant(targetStore)
                                .typemenu(mainCourse)
                                .build(),
                        Menu.builder()
                                .menuname("ชาเขียวนม")
                                .description("ชาเขียวมัทฉะพรีเมียม")
                                .imageurl("3.jpg")
                                .price(35.0)
                                .status(true)
                                .restaurant(targetStore)
                                .typemenu(drink)
                                .build()
                );

                menuRepository.saveAll(menus);
                System.out.println("✅ เพิ่มข้อมูลประเภทอาหารและเมนูเรียบร้อยแล้ว!");
            } else {
                System.out.println("⚠️ ไม่สามารถเพิ่มเมนูได้: กรุณาเพิ่มข้อมูลร้านค้า (Restaurant) ก่อน");
            }
        }
    }
}