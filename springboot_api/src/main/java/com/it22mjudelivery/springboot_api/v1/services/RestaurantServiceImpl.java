package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.OpeningHourDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RestaurantDto;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurantopeninghour;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RestaurantServiceImpl implements RestaurantService {
    private final RestaurantRepository restaurantRepository;
    private final TypeRestaurantRepository typeRestaurantRepository;

    public Restaurant doLoginRestaurant(String username, String password) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"));

        if (!restaurant.getPassword().equals(password)) {
            throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
        }
        return restaurant;
    }

    public boolean doRegisterRestaurant(RestaurantDto restaurantDto) {
        if (restaurantRepository.existsByUsername(restaurantDto.getUsername())) {
            throw new RuntimeException("ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว");
        }
        TypeRestaurant typeRestaurant = typeRestaurantRepository.findById(restaurantDto.getTypeid())
                .orElseThrow(() -> new RuntimeException("ไม่พบประเภทร้านค้า"));

        Restaurant toSaveRestaurant = Restaurant.builder()
                .username(restaurantDto.getUsername())
                .password(restaurantDto.getPassword())
                .restaurantname(restaurantDto.getRestaurantname())
                .typerestaurant(typeRestaurant)
                .latitude(restaurantDto.getLatitude())
                .longitude(restaurantDto.getLongitude())
                .restaurantimage(restaurantDto.getRestaurantimage())
                .imagecardid(restaurantDto.getImagecardid())
                .ownerfirstname(restaurantDto.getOwnerfirstname())
                .ownerlastname(restaurantDto.getOwnerlastname())
                .email(restaurantDto.getEmail())
                .phone(restaurantDto.getPhone())
                .registerdate(LocalDateTime.now())
                .statusopen(false)
                .verificationstatus("wait")
                .build();

        // แปลง DTO -> Entity แล้วผูกกลับไปหา restaurant (สำคัญ เพราะ FK อยู่ฝั่ง opening hour)
        List<Restaurantopeninghour> openingHours = toOpeningHourEntities(restaurantDto.getOpeningHours(), toSaveRestaurant);
        toSaveRestaurant.setOpeningHours(openingHours);

        restaurantRepository.save(toSaveRestaurant); // cascade = ALL จะเซฟ opening hours ให้อัตโนมัติ
        return true;
    }

    public Restaurant getRestaurantByUsername(String username) {
        return restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
    }

    public boolean updateStatusOpen(String username, boolean statusopen) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        restaurant.setStatusopen(statusopen);
        restaurantRepository.save(restaurant);
        return true;
    }

    public boolean updateProfileRestaurant(String username, String restaurantname, String restaurantimage,
                                           int typeid,
                                           double latitude, double longitude,
                                           List<OpeningHourDto> openingHourDtos,
                                           String ownerfirstname,
                                           String ownerlastname, String email, String phone, String ownerimage) {

        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        TypeRestaurant typeRestaurant = typeRestaurantRepository.findById(typeid)
                .orElseThrow(() -> new RuntimeException("ไม่พบประเภทร้านค้าที่ระบุ"));

        restaurant.setRestaurantname(restaurantname);
        restaurant.setTyperestaurant(typeRestaurant);
        restaurant.setRestaurantimage(restaurantimage);
        restaurant.setLatitude(latitude);
        restaurant.setLongitude(longitude);
        restaurant.setOwnerfirstname(ownerfirstname);
        restaurant.setOwnerlastname(ownerlastname);
        restaurant.setEmail(email);
        restaurant.setPhone(phone);
        restaurant.setImagecardid(ownerimage);

        // แก้ไข opening hours: เคลียร์ของเดิมแล้วใส่ใหม่ทั้งชุด
        // (orphanRemoval = true ที่ฝั่ง Restaurant จะลบแถวเก่าที่ไม่อยู่ใน list ใหม่ให้อัตโนมัติ)
        restaurant.getOpeningHours().clear();
        restaurant.getOpeningHours().addAll(toOpeningHourEntities(openingHourDtos, restaurant));

        restaurantRepository.save(restaurant);
        return true;
    }

    public void doCloseAccount(String username) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));
        restaurant.setVerificationstatus("close");
        restaurant.setNotapprovedetail(null);
        restaurantRepository.save(restaurant);
    }

    // ---- helper: แปลง OpeningHourDto -> RestaurantOpeningHour entity ----
    private List<Restaurantopeninghour> toOpeningHourEntities(List<OpeningHourDto> dtos, Restaurant restaurant) {
        List<Restaurantopeninghour> result = new ArrayList<>();
        if (dtos == null) {
            return result;
        }
        for (OpeningHourDto dto : dtos) {
            result.add(Restaurantopeninghour.builder()
                    .dayOfWeek(dto.getDayOfWeek())
                    .opentime(dto.getOpentime())
                    .closetime(dto.getClosetime())
                    .closed(dto.isClosed())
                    .restaurant(restaurant)
                    .build());
        }
        return result;
    }
}