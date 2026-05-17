package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.AdminRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RiderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService{
    private final AdminRepository adminRepository;
    private final RestaurantRepository restaurantRepository; // เปลี่ยนตรงนี้
    private final RiderRepository riderRepository;

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

    //--------Rider-------------------------------------------------------------------------------------
    @Override
    public List<Rider> getList_register_rider() {
        return riderRepository.findByVerificationStatus("wait");
    }

    @Override
    public Rider getRiderById(String studentId) {
        return riderRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้จัดส่ง ID: " + studentId));
    }

    @Override
    public void approveRider(String studentId) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + studentId));
        rider.setVerificationStatus("true");
        rider.setNotApproveDetail(null);
        riderRepository.save(rider);
    }

    @Override
    public void rejectRider(String studentId, String reason) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + studentId));

        rider.setVerificationStatus("false"); // ตั้งค่าเป็นไม่อนุมัติ
        rider.setNotApproveDetail(reason);  // ใส่เหตุผลที่ปฏิเสธ
        riderRepository.save(rider);
    }

}
