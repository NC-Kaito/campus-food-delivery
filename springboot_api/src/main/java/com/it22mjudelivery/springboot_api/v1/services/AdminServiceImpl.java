package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.AdminRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService{
    private final AdminRepository adminRepository;
    private final RestaurantRepository restaurantRepository; // เปลี่ยนตรงนี้

    public Admin doLoginAdmin(String username, String password) {
        Admin admin = adminRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));

        if(!admin.getPassword().equals(password)) {
            throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
        }
        return admin;
    }

    @Override
    public List<Restaurant> getList_register_rest() {
        return restaurantRepository.findByVerificationstatus("wait");
    }

    @Override
    public Restaurant getRestaurantById(String id) {
        return restaurantRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านอาหาร ID: " + id));
    }

    @Override
    public void approveRestaurant(String username) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));
        restaurant.setVerificationstatus("true");
        restaurant.setNotapprovedetail(null);
        restaurantRepository.save(restaurant);
    }

    @Override
    public void rejectRestaurant(String username, String reason) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));

        restaurant.setVerificationstatus("false"); // ตั้งค่าเป็นไม่อนุมัติ
        restaurant.setNotapprovedetail(reason);  // ใส่เหตุผลที่ปฏิเสธ
        restaurantRepository.save(restaurant);
    }


}
