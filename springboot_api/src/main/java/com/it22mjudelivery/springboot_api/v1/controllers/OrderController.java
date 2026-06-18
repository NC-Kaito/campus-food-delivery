package com.it22mjudelivery.springboot_api.v1.controllers;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Order; // 🎯 อิมพอร์ต Entity Order เพิ่มเข้ามา
import com.it22mjudelivery.springboot_api.v1.services.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List; // 🎯 อิมพอร์ต List เพิ่มเข้ามา
import java.util.Map;

@RestController
@RequestMapping("/v1/order")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OrderController {

    private final OrderService orderService;

    // 📥 1. ขารับเข้า: รับก้อนออเดอร์จากตะกร้าหน้าบ้าน มาสลักบันทึกลงตู้เบสข้อมูล
    @PostMapping("/confirmMemberOrder")
    public ResponseEntity<?> confirmMemberOrder(@RequestBody AddOrderDto addOrderDto){
        boolean result = orderService.memberConfirmOrder(addOrderDto);
        if (result) {
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "🛒 บันทึกคำสั่งซื้อเรียบร้อยแล้วคราบบบ"
            ));
        } else {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาดในระบบ ไม่สามารถบันทึกออเดอร์ได้"
            ));
        }
    }

    @GetMapping("/listOrderMember/{username}")
    public ResponseEntity<?> getOrderHistory(@PathVariable("username") String username) {
        try {
            // วิ่งทะลุผ่าน Layer ของชั้น Service เพื่อสอยลิสต์คำสั่งซื้อจริงขึ้นมา
            List<Order> historyList = orderService.getOrdersByMember(username);

            // ส่งก้อนข้อมูลพร้อมรหัส HTTP 200 กลับไปบอกหน้าบ้าน
            return ResponseEntity.ok(historyList);
        } catch (Exception e) {
            // ดักจับกรณีเบสล่ม ส่ง HTTP 500 แจ้งเตือนหน้าบ้านล่ม
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "🚨 เซิร์ฟเวอร์ขัดข้อง ไม่สามารถดึงประวัติออเดอร์ได้: " + e.getMessage()
            ));
        }
    }

    /// /////////////////////////////// Rider --
    @GetMapping("/waitingOrders")
    public ResponseEntity<?> getWaitingOrders() {
        try {
            // 🚀 เรียกใช้งานผ่านชั้น Service ตามที่ออกแบบไว้
            List<Order> orders = orderService.getWaitingOrders();
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาด: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/confirmOrderByRider")
    public ResponseEntity<?> confirmOrderByRider(@RequestBody Map<String, Object> data){
        try{
            String studentId = data.get("studentId").toString();
            int orderId = (int) data.get("orderId");

            boolean isResult = orderService.doConfirmOrderByRider(studentId, orderId);
            if (isResult) {
                return ResponseEntity.ok(Map.of(
                        "status", "success",
                        "message", "รับคำสั่งซื้อสำเร็จเรียบร้อยแล้ว!"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                        "status", "error",
                        "message", "ไม่สามารถรับออเดอร์นี้ได้ กรุณาลองใหม่อีกครั้ง"
                ));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาดในระบบ (Controller): " + e.getMessage()
            ));
        }
    }
}