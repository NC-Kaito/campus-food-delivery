package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailAddOnDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Order;
import com.it22mjudelivery.springboot_api.v1.entities.OrderDetail;
import com.it22mjudelivery.springboot_api.v1.entities.Orderdetailaddon;

import java.util.List;

public interface OrderService {
    boolean memberConfirmOrder(AddOrderDto addOrderDto);

    List<Order> getOrdersByMember(String username);

    //---- Rider ----

    List<Order> getWaitingOrders();

    List<Order> getActiveOrdersByRider(String username);

    boolean doConfirmOrderByRider(String studentId, int orderId);

    //---- Restaurant ----
    List<Order> getWaitingOrdersByRestaurant(String username);

    boolean doConfirmOrderByRestaurant(int orderId);

    List<Order> getActiveOrdersByRestaurant(String username);

    // เพิ่มไว้ตรงไหนก็ได้ใน interface (เช่น ต่อจาก getActiveOrdersByRider)
    boolean updateOrderStatus(int orderId, String newStatus);

    List<Order> getSuccessOrdersByRider(String username);

    // 🎯 เพิ่มการประกาศฟังก์ชันสำหรับดึงออเดอร์ที่รีวิวแล้ว
    List<Order> getReviewSuccessOrders(String studentId);
    // 🎯 ดึงออเดอร์รีวิวสำหรับ "ร้านค้า"
    List<Order> getReviewSuccessOrdersByRestaurant(String username);

}
