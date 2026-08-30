package com.it22mjudelivery.springboot_api.v1.RunDATABase;

import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeMenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

@Component
@RequiredArgsConstructor
public class RunAddTypeMenu implements CommandLineRunner {
    private final TypeMenuRepository typeMenuRepository;

    @Override
    public void run(String... args) throws Exception {
        if (typeMenuRepository.count() == 0) {
            List<TypeMenu> types = Arrays.asList(
                    TypeMenu.builder().typemenuName("อาหารตามสั่ง").build(),
                    TypeMenu.builder().typemenuName("เส้น").build(),
                    TypeMenu.builder().typemenuName("ข้าวราดแกง").build(),
                    TypeMenu.builder().typemenuName("เครื่องดื่ม").build(),
                    TypeMenu.builder().typemenuName("ของหวาน").build()
            );

            typeMenuRepository.saveAll(types);
            System.out.println("✅ เพิ่มข้อมูลประเภทเมนูเริ่มต้นเรียบร้อยแล้ว!");
        }
    }
}
