package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v2.entities.Order;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface OrderService {
    boolean memberConfirmOrder(AddOrderDto addOrderDto);

    List<Order> getOrdersByMember(String username);

    boolean reportIssue(int orderId, String issueDetail, org.springframework.web.multipart.MultipartFile issueImage);

    //---- Rider ----

    List<Order> getWaitingOrders();

    List<Order> getOrdersNotifyByRider(String username);

    List<Order> getActiveOrdersByRider(String username);

    boolean doConfirmOrderByRider(String studentId, int orderId);

    // เพิ่ม Response DTO แบบง่ายๆ ใช้ Map หรือสร้างคลาสใหม่ก็ได้ (ในที่นี้ขอคืนเป็น List<Map> เพื่อความรวดเร็ว)
    List<Map<String, Object>> getRiderIncomeByDateRange(String studentId, LocalDateTime startDate, LocalDateTime endDate);

    //---- Restaurant ----
    List<Order> getWaitingOrdersByRestaurant(String username);

    boolean doConfirmOrderByRestaurant(int orderId);

    List<Order> getActiveOrdersByRestaurant(String username);

    List<Order> getCancelOrdersByRestaurant(String username);

    List getSuccessOrdersByRestaurant(String username);

    // เพิ่มไว้ตรงไหนก็ได้ใน interface (เช่น ต่อจาก getActiveOrdersByRider)
    boolean updateOrderStatus(int orderId, String newStatus);

    boolean updateOrderSuccess(int orderId, String newStatus);


    List<Order> getSuccessOrdersByRider(String username);

    List getCancelOrdersByRider(String username);

    // 🎯 เพิ่มการประกาศฟังก์ชันสำหรับดึงออเดอร์ที่รีวิวแล้ว
    List<Order> getReviewSuccessOrders(String studentId);
    // 🎯 ดึงออเดอร์รีวิวสำหรับ "ร้านค้า"
    List<Order> getReviewSuccessOrdersByRestaurant(String username);

    List<Map<String, Object>> getRestaurantIncomeByDateRange(String username, LocalDateTime startDate, LocalDateTime endDate);

    void autoCancelExpiredOrders();

    void autoRejectExpiredRestaurantOrders();
}
