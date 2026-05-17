package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.AdminRepository;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

public interface AdminService {

    public Admin doLoginAdmin(String username, String password);

    List<Restaurant> getList_register_rest();
    Restaurant getRestaurantById(String id);

    // เพิ่ม Method สำหรับอนุมัติร้านค้า
    void approveRestaurant(String username);

    // เพิ่ม Method สำหรับปฏิเสธร้านค้าพร้อมเหตุผล
    void rejectRestaurant(String username, String reason);// เพิ่ม Parameter

    List<Rider> getList_register_rider();
    Rider getRiderById(String studentId);
    void  approveRider(String studentId);
    void  rejectRider(String studentId, String reason);



}
