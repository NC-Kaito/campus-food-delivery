package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailAddOnDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {
    @Autowired
    private final OrderRepository orderRepo;

    @Autowired
    private final OrderDetailRepository orderDetailRepo;

    @Autowired
    private final OrderDetailAddonRepository orderDetailAddonRepo;

    @Autowired
    private final MemberRepository memberRepo;

    @Autowired
    private final RestaurantRepository restaurantRepo;

    @Autowired
    private final MenuRepository menuRepo;

    @Autowired
    private final MenuaddondetailRepository menuaddondetailRepo;

    @Autowired
    private final RiderRepository riderRepo;

    @Override
    @Transactional // ดักจับ Transaction เผื่อบันทึกตารางลูกตัวไหนพลาด ระบบจะได้ Rollback อัตโนมัติ
    public boolean memberConfirmOrder(AddOrderDto addOrderDto) {

        String memberUser = addOrderDto.getMemberUsername().trim();
        String restUser = addOrderDto.getRestaurantUsername().trim();

        System.out.println("🔍 กำลังค้นหาผู้ใช้: " + memberUser);
        Member member = memberRepo.findByUsername(memberUser)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้ใช้ยสเนม: " + memberUser));

        System.out.println("🔍 กำลังค้นหาร้านค้า: " + restUser);
        Restaurant restaurant = restaurantRepo.findByUsername(restUser)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้ายูสเนม: " + restUser));

        try {
            // 1. บันทึกตารางหลัก (Orders)
            Order order = Order.builder()
                    .orderdate(LocalDateTime.now())
                    .delivery_fee(addOrderDto.getDeliveryFee())
                    .totalprice(addOrderDto.getTotalPrice())
                    .addressdetail(addOrderDto.getAddressDetail())
                    .latitude(addOrderDto.getLatitude())
                    .longitude(addOrderDto.getLongitude())
                    .orderstatus("WaitingRider")
                    .member(member)
                    .restaurant(restaurant)
                    .build();

            Order savedOrder = orderRepo.save(order);

            // 2. วนลูปแกะรายการอาหาร (OrderDetail) จากก้อนรายการใน addOrderDto
            if (addOrderDto.getItems() != null) {
                for (AddOrderDetailDto detailDto : addOrderDto.getItems()) {

                    Menu menu = menuRepo.findById(detailDto.getMenuId())
                            .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสMenu"));

                    // 🎯 แก้ไข: เปลี่ยนจาก addOrderDetailDto เป็น detailDto (ตามรอบการวนลูปจริง) เส้นแดงจะหายไปครับ
                    OrderDetail orderDetail = OrderDetail.builder()
                            .qty(detailDto.getQty())
                            .subtotal(detailDto.getSubTotal())
                            .note(detailDto.getNote())
                            .order(savedOrder)
                            .menu(menu)
                            .build();

                    OrderDetail savdOrderDetail = orderDetailRepo.save(orderDetail);

                    // 3. วนลูปแกะรายการท็อปปิ้งเสริม (Orderdetailaddon) ที่ผูกอยู่กับจานอาหารรอบนั้นๆ
                    // 🎯 แก้ไข: เปลี่ยนจาก addOrderDetailDto.getAddons() เป็น detailDto.getAddons()
                    if (detailDto.getAddons() != null) {
                        for (AddOrderDetailAddOnDto addOnDto : detailDto.getAddons()) {

                            // 🎯 แก้ไข: เปลี่ยนจาก addOrderDetailAddOnDto เป็น addOnDto ที่ดึงมาจากลูปท็อปปิ้งรอบนั้นๆ
                            Menuaddondetail menuaddondetail = menuaddondetailRepo.findById(addOnDto.getAddondetailid())
                                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสAddOn"));

                            Orderdetailaddon orderdetailaddon = Orderdetailaddon.builder()
                                    .orderDetail(savdOrderDetail)
                                    .menuaddondetail(menuaddondetail)
                                    .priceAtOrder(menuaddondetail.getAddonprice())
                                    .build();

                            orderDetailAddonRepo.save(orderdetailaddon);
                        }
                    }
                }
            }
            return true; // บันทึกสำเร็จทุกตาราง ส่งค่ากลับไปบอก Controller

        } catch (Exception e) {
            System.out.println("🚨 เกิดข้อผิดพลาดในระบบ Service: " + e.getMessage());
            e.printStackTrace();
        }

        return false;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Order> getOrdersByMember(String username) {
        System.out.println("📦 [SERVICE] กำลังดึงประวัติคำสั่งซื้อของกลุ่มสมาชิก: " + username);
        try {
            return orderRepo.findOrdersByMemberUsername(username.trim());
        } catch (Exception e) {
            System.out.println("🚨 เกิดข้อผิดพลาดในการดึงประวัติออเดอร์ที่ Service: " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    @Override
    public List<Order> getWaitingOrders() {
        try {
            // 🔍 ค้นหาออเดอร์ที่มีสถานะ "WaitingRider" จาก Repository
            return orderRepo.findByOrderstatusOrderByOrderidDesc("WaitingRider");
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public boolean doConfirmOrderByRider(String studentId, int orderId) {
        try{
        Rider rider = riderRepo.findByStudentid(studentId).orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบชื่อผู้ใช้งาน"));

        Order order = orderRepo.findById(orderId).orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อในระบบ"));

        order.setRider(rider);
        order.setOrderstatus("WaitingRestaurant");
        order.setPickuptime(LocalTime.now());
        orderRepo.save(order);
        return true;
        }catch (Exception e){
            new RuntimeException("เกิดข้อผิดพลาดที่ระบบ");
            return false;
        }
    }
}