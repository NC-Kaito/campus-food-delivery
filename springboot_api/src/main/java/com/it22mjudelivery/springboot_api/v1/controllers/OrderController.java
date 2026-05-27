package com.it22mjudelivery.springboot_api.v1.controllers;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.services.OrderService;
import lombok.RequiredArgsConstructor;
import org.apache.coyote.Response;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/order")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class OrderController {
    private final OrderService orderService;

    @PostMapping("/confirmMemberOrder")
    public ResponseEntity<?> confirmMemberOrder(@RequestBody AddOrderDto addOrderDto){

        boolean result = orderService.memberConfirmOrder(addOrderDto);
        if (result) {
            // บันทึกสำเร็จ: ส่ง HTTP 200 แจ้งฝั่ง Flutter ให้เคลียร์ตะกร้าและเด้งหน้าจอได้เลย
            return ResponseEntity.ok(Map.of(
                    "status", "success",
                    "message", "🛒 บันทึกคำสั่งซื้อเรียบร้อยแล้วคราบบบ"
            ));
        } else {
            // เกิดข้อผิดพลาดฝั่ง DB: ส่ง HTTP 500 แจ้งเตือนแอป
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "error",
                    "message", "เกิดข้อผิดพลาดในระบบ ไม่สามารถบันทึกออเดอร์ได้"
            ));
        }
    }
}
