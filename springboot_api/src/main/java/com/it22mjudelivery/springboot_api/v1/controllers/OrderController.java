package com.it22mjudelivery.springboot_api.v1.controllers;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Order; // 🎯 อิมพอร์ต Entity Order เพิ่มเข้ามา
import com.it22mjudelivery.springboot_api.v1.services.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List; // 🎯 อิมพอร์ต List เพิ่มเข้ามา
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

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

    @PostMapping("/reportIssue")
    public ResponseEntity<?> reportIssue(
            @RequestParam("orderId") int orderId,
            @RequestParam("issueDetail") String issueDetail,
            @RequestParam(value = "issueImage", required = false) org.springframework.web.multipart.MultipartFile issueImage) {

        try {
            boolean isSuccess = orderService.reportIssue(orderId, issueDetail, issueImage);

            if (isSuccess) {
                return ResponseEntity.ok("ส่งเรื่องแจ้งปัญหาเรียบร้อยแล้ว");
            } else {
                return ResponseEntity.badRequest().body("ไม่สามารถส่งเรื่องแจ้งปัญหาได้");
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: " + e.getMessage());
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

    @GetMapping("/rider/{username}/active")
    public ResponseEntity<?> getActiveOrdersForRider(@PathVariable String username) {
        try {
            List<Order> activeOrders = orderService.getActiveOrdersByRider(username);
            return ResponseEntity.ok(activeOrders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
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

    @GetMapping("/rider/{username}/success")
    public ResponseEntity<?> getSuccessOrdersForRider(@PathVariable String username) {
        try {
            List<Order> successOrders = orderService.getSuccessOrdersByRider(username);
            return ResponseEntity.ok(successOrders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/rider/{studentId}/income")
    public ResponseEntity<?> getRiderIncome(
            @PathVariable String studentId,
            @RequestParam("startDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam("endDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {

        try {
            // เรียกใช้ Service ที่เราเขียนไว้
            List<Map<String, Object>> incomeSummary = orderService.getRiderIncomeByDateRange(studentId, startDate, endDate);
            return ResponseEntity.ok(incomeSummary);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("ไม่สามารถดึงข้อมูลรายได้ได้: " + e.getMessage());
        }
    }

    /// //////////////// Restaurant
    @GetMapping("/restaurant/{username}/waitingOrdersByRestaurant")
    public ResponseEntity<?> getWaitingOrdersByRestaurant(@PathVariable String username) {
        try {
            List<Order> orders = orderService.getWaitingOrdersByRestaurant(username);
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาด: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/confirmOrderByRestaurant")
    public ResponseEntity<?> confirmOrderByRestaurant(@RequestBody Map<String, Object> data){
        try{
            int orderId = (int) data.get("orderId");

            boolean isResult = orderService.doConfirmOrderByRestaurant(orderId);
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

    @GetMapping("/restaurant/{username}/active")
    public ResponseEntity<?> getActiveOrdersByRestaurant(@PathVariable String username) {
        try {
            List<Order> activeOrders = orderService.getActiveOrdersByRestaurant(username);
            return ResponseEntity.ok(activeOrders);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/updateStatus")
    public ResponseEntity<?> updateOrderStatus(@RequestBody Map<String, Object> requestData) {
        try {
            // รับค่า orderId และ status ที่ส่งมาจาก Flutter
            int orderId = Integer.parseInt(requestData.get("orderId").toString());
            String status = requestData.get("status").toString();

            // เรียกใช้ Service
            boolean isSuccess = orderService.updateOrderStatus(orderId, status);

            if (isSuccess) {
                return ResponseEntity.ok(Map.of(
                        "status", "success",
                        "message", "อัปเดตสถานะเป็น " + status + " สำเร็จ"
                ));
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                        "status", "error",
                        "message", "ไม่สามารถอัปเดตสถานะได้"
                ));
            }

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาดที่ระบบส่วนกลาง: " + e.getMessage()
            ));
        }
    }

    @GetMapping("/rider/{studentId}/review")
    public ResponseEntity<List<Order>> getReviewSuccessOrders(@PathVariable String studentId) {
        List<Order> orders = orderService.getReviewSuccessOrders(studentId);
        return ResponseEntity.ok(orders);
    }

    // 🎯 API เส้นใหม่สำหรับให้ "ร้านค้า" ดึงรีวิวของตัวเองโดยเฉพาะ
    @GetMapping("/restaurant/{username}/review")
    public ResponseEntity<List<Order>> getReviewSuccessOrdersByRestaurant(@PathVariable String username) {
        try {
            List<Order> orders = orderService.getReviewSuccessOrdersByRestaurant(username);
            return ResponseEntity.ok(orders);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    // 🎯 1. สร้าง Map เก็บสถานะการล็อกไว้ใน Memory ของ Spring Boot
    private final ConcurrentHashMap<Integer, OrderLock> lockedOrders = new ConcurrentHashMap<>();

    // 🎯 2. คลาสย่อยสำหรับเก็บข้อมูลคนล็อกและเวลา
    private static class OrderLock {
        String riderId;
        LocalDateTime lockedAt;

        OrderLock(String riderId) {
            this.riderId = riderId;
            this.lockedAt = LocalDateTime.now();
        }
    }

    // 🎯 3. API สำหรับขอล็อกออเดอร์
    @PostMapping("/lockOrder")
    public ResponseEntity<?> lockOrder(@RequestParam int orderId, @RequestParam String riderId) {
        OrderLock currentLock = lockedOrders.get(orderId);

        if (currentLock != null) {
            // ถ้ามีคนล็อกค้างไว้นานเกิน 1 นาที (เผื่อแอปเขาค้างหรือเน็ตหลุด) ให้ปลดล็อกอัตโนมัติ
            if (currentLock.lockedAt.isBefore(LocalDateTime.now().minusMinutes(1))) {
                lockedOrders.remove(orderId);
            }
            // ถ้าเวลาไม่เกิน 1 นาที และคนที่ล็อกอยู่ "ไม่ใช่" ไรเดอร์คนนี้ ให้เด้งกลับไปบอกว่ามีคนดูอยู่
            else if (!currentLock.riderId.equals(riderId)) {
                return ResponseEntity.status(409).body("มีไรเดอร์คนอื่นกำลังพิจารณาออเดอร์นี้อยู่");
            }
        }

        // อนุมัติให้ล็อกได้
        lockedOrders.put(orderId, new OrderLock(riderId));
        return ResponseEntity.ok("ล็อกออเดอร์สำเร็จ");
    }

    // 🎯 4. API สำหรับปลดล็อกออเดอร์
    @PostMapping("/unlockOrder")
    public ResponseEntity<?> unlockOrder(@RequestParam int orderId, @RequestParam String riderId) {
        OrderLock currentLock = lockedOrders.get(orderId);

        // ยอมให้ปลดล็อกได้เฉพาะคนที่ล็อกไว้เท่านั้น
        if (currentLock != null && currentLock.riderId.equals(riderId)) {
            lockedOrders.remove(orderId);
        }
        return ResponseEntity.ok("ปลดล็อกออเดอร์สำเร็จ");
    }
}
