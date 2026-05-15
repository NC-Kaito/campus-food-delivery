package com.it22mjudelivery.springboot_api.v1.RunDATABase;

import com.it22mjudelivery.springboot_api.SpringbootApiApplication;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

public class RunRestaurant {
    public static void main(String[] args) {
        ApplicationContext context = SpringApplication.run(SpringbootApiApplication.class, args);

        RestaurantRepository restaurantRepository = context.getBean(RestaurantRepository.class);
        TypeRestaurantRepository typeRestaurantRepository = context.getBean(TypeRestaurantRepository.class);

        // ดึง TypeRestaurant จาก DB (ปรับ id ให้ตรงกับที่มีในฐานข้อมูล)
        TypeRestaurant type1 = typeRestaurantRepository.findById(1).orElseThrow();
        TypeRestaurant type2 = typeRestaurantRepository.findById(2).orElseThrow();
        TypeRestaurant type3 = typeRestaurantRepository.findById(3).orElseThrow();

        // ----- Insert 5 Restaurants -------------------------
        List<Restaurant> restaurants = List.of(

                Restaurant.builder()
                        .username("rest01")
                        .password("12345678")
                        .restaurantname("ร้านข้าวมันไก่เจ้าอร่อย")
                        .restaurantimage("images/restaurant/rest01.png")
                        .opentime(LocalTime.of(8, 0))
                        .closetime(LocalTime.of(20, 0))
                        .openDay(127)
                        .latitude(18.7883)
                        .longitude(98.9853)
                        .lease_agreement_img("images/lease/rest01_lease.png")
                        .ownerfirstname("สมชาย")
                        .ownerlastname("ใจดี")
                        .email("rest01@example.com")
                        .phone("0812345678")
                        .statusopen(true)
                        .registerdate(LocalDateTime.now())
                        .verificationstatus("wait")
                        .notapprovedetail(null)
                        .typerestaurant(type1)
                        .build(),

                Restaurant.builder()
                        .username("rest02")
                        .password("12345678")
                        .restaurantname("ร้านก๋วยเตี๋ยวเรือป้าแดง")
                        .restaurantimage("images/restaurant/rest02.png")
                        .opentime(LocalTime.of(9, 0))
                        .closetime(LocalTime.of(18, 0))
                        .openDay(62)   // จันทร์-ศุกร์ (0111110)
                        .latitude(18.7910)
                        .longitude(98.9801)
                        .lease_agreement_img("images/lease/rest01_lease.png")
                        .ownerfirstname("วิภา")
                        .ownerlastname("มีสุข")
                        .email("rest02@example.com")
                        .phone("0823456789")
                        .statusopen(true)
                        .registerdate(LocalDateTime.now())
                        .verificationstatus("wait")
                        .notapprovedetail(null)
                        .typerestaurant(type1)
                        .build(),

                Restaurant.builder()
                        .username("rest03")
                        .password("12345678")
                        .restaurantname("ร้านพิซซ่าและพาสต้า")
                        .restaurantimage("images/restaurant/rest03.png")
                        .opentime(LocalTime.of(11, 0))
                        .closetime(LocalTime.of(22, 0))
                        .openDay(127)
                        .latitude(18.7955)
                        .longitude(98.9920)
                        .lease_agreement_img("images/lease/rest01_lease.png")
                        .ownerfirstname("ธนวัฒน์")
                        .ownerlastname("สกุลดี")
                        .email("rest03@example.com")
                        .phone("0834567890")
                        .statusopen(true)
                        .registerdate(LocalDateTime.now())
                        .verificationstatus("wait")
                        .notapprovedetail(null)
                        .typerestaurant(type2)
                        .build(),

                Restaurant.builder()
                        .username("rest04")
                        .password("12345678")
                        .restaurantname("ร้านซูชิและอาหารญี่ปุ่น")
                        .restaurantimage("images/restaurant/rest04.png")
                        .opentime(LocalTime.of(10, 30))
                        .closetime(LocalTime.of(21, 0))
                        .openDay(119)  // อาทิตย์-พฤหัส (1110111)
                        .latitude(18.7820)
                        .longitude(98.9870)
                        .lease_agreement_img("images/lease/rest01_lease.png")
                        .ownerfirstname("ยูกิ")
                        .ownerlastname("ทานากะ")
                        .email("rest04@example.com")
                        .phone("0845678901")
                        .statusopen(false)
                        .registerdate(LocalDateTime.now())
                        .verificationstatus("wait")
                        .notapprovedetail(null)
                        .typerestaurant(type2)
                        .build(),

                Restaurant.builder()
                        .username("rest05")
                        .password("12345678")
                        .restaurantname("ร้านส้มตำและอาหารอีสาน")
                        .restaurantimage("images/restaurant/rest05.png")
                        .opentime(LocalTime.of(7, 0))
                        .closetime(LocalTime.of(17, 0))
                        .openDay(127)
                        .latitude(18.7998)
                        .longitude(98.9755)
                        .lease_agreement_img("images/lease/rest01_lease.png")
                        .ownerfirstname("มาลี")
                        .ownerlastname("ดอกไม้")
                        .email("rest05@example.com")
                        .phone("0856789012")
                        .statusopen(true)
                        .registerdate(LocalDateTime.now())
                        .verificationstatus("ture")
                        .notapprovedetail(null)
                        .typerestaurant(type3)
                        .build()
        );

        restaurantRepository.saveAll(restaurants);

        System.out.println("Inserted restaurants successfully!");

        SpringApplication.exit(context);
    }
}