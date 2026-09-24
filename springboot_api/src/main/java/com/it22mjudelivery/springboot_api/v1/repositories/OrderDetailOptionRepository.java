package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.OrderDetail;
import com.it22mjudelivery.springboot_api.v1.entities.Orderdetailoption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderDetailOptionRepository extends JpaRepository<Orderdetailoption, Integer> {

    // ดึงตัวเลือกที่สั่งตาม OrderDetail
    List findByOrderDetail(OrderDetail orderDetail);

    List findByOrderDetail_Orderdetailid(Integer orderdetailid);
}