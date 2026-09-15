package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailAddOnDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailCurryDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.hibernate.Hibernate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Array;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

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

    @Autowired
    private final OrderdetailcurryRepository orderdetailcurryRepo;

    private final CloudinaryService cloudinaryService;

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
            // 2. วนลูปแกะรายการอาหาร (OrderDetail) จากก้อนรายการใน addOrderDto
            if (addOrderDto.getItems() != null) {
                for (AddOrderDetailDto detailDto : addOrderDto.getItems()) {

                    Menu menu = menuRepo.findById(detailDto.getMenuId())
                            .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสMenu"));

                    // 🎯 จัดการชื่อเมนูและราคา Snapshot (ถ้า DTO ว่าง ให้ดึงจาก Entity Menu)
                    String resolvedMenuName = (detailDto.getMenuNameAtOrder() != null && !detailDto.getMenuNameAtOrder().trim().isEmpty())
                            ? detailDto.getMenuNameAtOrder()
                            : menu.getMenuname();

                    double resolvedPrice = detailDto.getPriceAtOrder() > 0
                            ? detailDto.getPriceAtOrder()
                            : menu.getPrice();

                    OrderDetail orderDetail = OrderDetail.builder()
                            .menuNameAtOrder(resolvedMenuName) // 🎯 บันทึก Snapshot ชื่อเมนู
                            .priceAtOrder(resolvedPrice)       // 🎯 บันทึก Snapshot ราคาเมนู
                            .qty(detailDto.getQty())
                            .subtotal(detailDto.getSubTotal())
                            .note(detailDto.getNote())
                            .order(savedOrder)
                            .menu(menu)
                            .build();

                    OrderDetail savdOrderDetail = orderDetailRepo.save(orderDetail);

                    // 3. วนลูปแกะรายการท็อปปิ้งเสริม (Orderdetailaddon)
                    if (detailDto.getAddons() != null) {
                        for (AddOrderDetailAddOnDto addOnDto : detailDto.getAddons()) {

                            Menuaddondetail menuaddondetail = menuaddondetailRepo.findById(addOnDto.getAddondetailid())
                                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสAddOn"));

                            // 🎯 จัดการชื่อ Add-on และราคา Snapshot
                            String resolvedAddonName = (addOnDto.getAddonNameAtOrder() != null && !addOnDto.getAddonNameAtOrder().trim().isEmpty())
                                    ? addOnDto.getAddonNameAtOrder()
                                    : (menuaddondetail.getAddonmenu() != null ? menuaddondetail.getAddonmenu().getAddonname() : "ตัวเลือกเสริม");

                            double resolvedAddonPrice = addOnDto.getPriceAtOrder() > 0
                                    ? addOnDto.getPriceAtOrder()
                                    : menuaddondetail.getAddonprice();

                            Orderdetailaddon orderdetailaddon = Orderdetailaddon.builder()
                                    .orderDetail(savdOrderDetail)
                                    .menuaddondetail(menuaddondetail)
                                    .addonNameAtOrder(resolvedAddonName) // 🎯 บันทึก Snapshot ชื่อ Add-on
                                    .priceAtOrder(resolvedAddonPrice)     // 🎯 บันทึก Snapshot ราคา Add-on
                                    .addon_qty(addOnDto.getAddon_qty() > 0 ? addOnDto.getAddon_qty() : 1)
                                    .build();

                            orderDetailAddonRepo.save(orderdetailaddon);
                        }
                    }

                    // 4. วนลูปแกะรายการกับข้าวราดแกง (Orderdetailcurry)
                    if (detailDto.getOrderDetailCurries() != null) {
                        for (AddOrderDetailCurryDto curryDto : detailDto.getOrderDetailCurries()) {

                            Menu curryMenu = menuRepo.findById(curryDto.getMenuId())
                                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสเมนูกับข้าว"));

                            Orderdetailcurry orderdetailcurry = Orderdetailcurry.builder()
                                    .orderDetail(savdOrderDetail)
                                    .menu(curryMenu)
                                    .priceAtOrder(curryDto.getPriceAtOrder())
                                    .build();

                            orderdetailcurryRepo.save(orderdetailcurry);
                        }
                    }
                }
            } return true; // บันทึกสำเร็จทุกตาราง ส่งค่ากลับไปบอก Controller

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
            List<Order> orders = orderRepo.findOrdersByMemberUsername(username.trim());

            // 🎯 บังคับโหลดทีละ collection ตามลำดับ แทนที่จะปล่อยให้ Hibernate
            // พยายามโหลด Set ทั้งสองตัวพร้อมกันแบบ EAGER ซึ่งชนกันจนเกิด
            // ConcurrentModificationException
            for (Order order : orders) {
                for (OrderDetail detail : order.getOrderDetails()) {
                    Hibernate.initialize(detail.getOrderDetailAddons());
                    Hibernate.initialize(detail.getOrderDetailCurries());
                }
            }

            return orders;
        } catch (Exception e) {
            System.out.println("🚨 เกิดข้อผิดพลาดในการดึงประวัติออเดอร์ที่ Service: " + e.getMessage());
            e.printStackTrace();
            return List.of();
        }
    }

    @Override
    @Transactional
    public boolean reportIssue(int orderId, String issueDetail, org.springframework.web.multipart.MultipartFile issueImage) {
        try {
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            String imageUrl = "";
            if (issueImage != null && !issueImage.isEmpty()) {
                // 🎯 บันทึก/อัปโหลดไฟล์รูปภาพเพื่อรับ URL กลับมา
                imageUrl = cloudinaryService.uploadImage(issueImage, "maejo_delivery/issues");
            }

            order.setCanceldetail(issueDetail);

            if (!imageUrl.isEmpty()) {
                order.setCancelimage(imageUrl); // 🎯 บันทึก URL ลง Database
            }

            order.setOrderstatus("issue_reported");
            orderRepo.save(order);

            return true;
        } catch (Exception e) {
            System.err.println("🚨 เกิดข้อผิดพลาดในการแจ้งปัญหา: " + e.getMessage());
            e.printStackTrace();
            return false;
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
    public List<Order> getActiveOrdersByRider(String username) {
        try {
            List<String> activeOrderStatus = Arrays.asList("WaitingRestaurant","goingToRestaurant", "delivery", "arrived" );
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, activeOrderStatus);
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

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getRiderIncomeByDateRange(String studentId, LocalDateTime startDate, LocalDateTime endDate) {
        try {
            // 1. ดึงข้อมูลจาก Query ที่เราสร้างไว้
            List<Order> orders = orderRepo.findRiderSuccessOrdersByDateRange(studentId, startDate, endDate);

            // 2. สร้าง Map เพื่อจัดกลุ่มข้อมูลเป็น "รายวัน" (เช่น "26 ส.ค. 2569" -> ออเดอร์ทั้งหมดในวันนั้น)
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");

            // ใช้ LinkedHashMap เพื่อรักษาลำดับของวันที่เอาไว้
            Map<String, Map<String, Object>> dailySummary = new LinkedHashMap<>();

            for (Order order : orders) {
                String dateKey = order.getOrderdate().format(formatter); // แปลงวันที่เป็น String

                // ถ้ามีวันที่นี้ใน Map แล้ว ให้ดึงมาบวกเพิ่ม
                Map<String, Object> dayData = dailySummary.getOrDefault(dateKey, new LinkedHashMap<>());

                int currentRounds = (int) dayData.getOrDefault("rounds", 0);
                double currentIncome = (double) dayData.getOrDefault("amount", 0.0);

                // สมมติว่ารายได้ของไรเดอร์คือค่าจัดส่ง (Delivery Fee)
                double deliveryFee = order.getDelivery_fee();

                dayData.put("date", dateKey);
                dayData.put("rounds", currentRounds + 1);
                dayData.put("amount", currentIncome + deliveryFee);

                dailySummary.put(dateKey, dayData);
            }

            // 3. แปลง Map กลับเป็น List เพื่อส่งเป็น JSON
            return new ArrayList<>(dailySummary.values());

        } catch (Exception e) {
            System.err.println("🚨 เกิดข้อผิดพลาดในการดึงรายงานรายได้: " + e.getMessage());
            return List.of();
        }
    }


    //---- Restaurant ----

    @Override
    public List<Order> getWaitingOrdersByRestaurant(String username) {
        try {
            List<String> order = Arrays.asList("WaitingRestaurant");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, order);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public boolean doConfirmOrderByRestaurant(int orderId) {
        try{
            Order order = orderRepo.findById(orderId).orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบรายการคำสั่งซื้อในระบบ"));

            order.setOrderstatus("delivery");
            orderRepo.save(order);
            return true;
        }catch (Exception e){
            System.err.println("Error confirmOrderByRestaurant: " + e.getMessage());
            return false;
        }
    }

    @Override
    public List<Order> getActiveOrdersByRestaurant(String username) {
        try {
            List<String> activeOrderStatus = Arrays.asList("goingToRestaurant","delivery");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, activeOrderStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่ต้องทำได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getCancelOrdersByRestaurant(String username) {
        try {
            List<String> cancelOrderStatus = Arrays.asList("issue_reported", "reject");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, cancelOrderStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่ต้องทำได้: " + e.getMessage());
        }
    }

    @Override
    public List getSuccessOrdersByRestaurant(String username) {
        try {
            // 🎯 ดึงสถานะที่ถือว่าสำเร็จแล้วทั้งหมด (รองรับทั้งตัวพิมพ์เล็กและตัวพิมพ์ใหญ่)
            List successStatus = Arrays.asList("delivered", "Success", "success", "completed");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, successStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่สำเร็จแล้วของร้านค้าได้: " + e.getMessage());
        }
    }


    @Override
    @Transactional
    public boolean updateOrderSuccess(int orderId, String newStatus) {
        try {
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            if(newStatus.equalsIgnoreCase("success")){
                order.setSuccesstime(LocalTime.now());
                order.setOrderstatus("success");
            } else {
                order.setOrderstatus(newStatus);
            }
            orderRepo.save(order);

            return true;
        } catch (Exception e) {
            System.err.println("🚨 อัปเดตสถานะไม่สำเร็จ: " + e.getMessage());
            return false;
        }
    }



    @Override
    @Transactional
    public boolean updateOrderStatus(int orderId, String newStatus) {
        try {
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            if(newStatus.equalsIgnoreCase("success")){
                order.setSuccesstime(LocalTime.now());
                order.setOrderstatus("success"); // 🎯 บันทึกเป็นตัวพิมพ์เล็กให้เป็นมาตรฐานเดียวกัน
            } else {
                order.setOrderstatus(newStatus);
            }
            orderRepo.save(order);

            return true;
        } catch (Exception e) {
            System.err.println("🚨 อัปเดตสถานะไม่สำเร็จ: " + e.getMessage());
            return false;
        }
    }

    @Override
    public List<Order> getSuccessOrdersByRider(String username) {
        try {
            // ดึงเฉพาะออเดอร์ที่สถานะเป็น Success หรือ Completed
            List<String> successStatus = Arrays.asList("delivered", "Success", "success", "reviewSuccess");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, successStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่สำเร็จแล้วได้: " + e.getMessage());
        }
    }

    @Override
    public List getCancelOrdersByRider(String username) {
        try {
            // 🎯 กำหนดกลุ่มสถานะที่ถือว่าออเดอร์นี้ถูกยกเลิก/มีปัญหา
            List cancelStatus = Arrays.asList("cancel", "cancelled", "issue_reported", "reject");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, cancelStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่ถูกยกเลิกของไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getReviewSuccessOrders(String studentId) {
        try {
            // 🎯 กำหนดสถานะเป็น "reviewSuccess" (เช็กให้ตรงกับตอนที่บันทึกลงฐานข้อมูลด้วยนะครับ)
            List<String> reviewStatus = Arrays.asList("reviewSuccess");

            // อาศัยฟังก์ชันเดิมที่มีอยู่แล้วใน Repository มาใช้ได้เลยครับ สะดวกมากๆ
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(studentId, reviewStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รีวิวแล้วได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getReviewSuccessOrdersByRestaurant(String username) {
        try {
            // 🎯 กำหนดสถานะเป็น "reviewSuccess"
            List<String> reviewStatus = Arrays.asList("reviewSuccess");

            // 🎯 ใช้ฟังก์ชันค้นหาจาก Restaurant_Username ที่คุณนารีย์มีอยู่ใน Repository อยู่แล้ว
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, reviewStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รีวิวแล้วของร้านค้าได้: " + e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getRestaurantIncomeByDateRange(String username, LocalDateTime startDate, LocalDateTime endDate) {
        try {
            // 1. ดึงออเดอร์ที่สำเร็จแล้วของร้านค้าตามช่วงวันที่กำหนด
            List<Order> orders = orderRepo.findRestaurantSuccessOrdersByDateRange(username, startDate, endDate);

            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            Map<String, Map<String, Object>> dailySummary = new LinkedHashMap<>();

            for (Order order : orders) {
                String dateKey = order.getOrderdate().format(formatter);

                Map<String, Object> dayData = dailySummary.getOrDefault(dateKey, new LinkedHashMap<>());

                int currentOrdersCount = (int) dayData.getOrDefault("rounds", 0);
                double currentIncome = (double) dayData.getOrDefault("amount", 0.0);

                // 🎯 รายรับของร้านค้า = ยอดรวมทั้งหมด - ค่าจัดส่ง
                double foodIncome = order.getTotalprice() - order.getDelivery_fee();

                dayData.put("date", dateKey);
                dayData.put("rounds", currentOrdersCount + 1);
                dayData.put("amount", currentIncome + foodIncome);

                dailySummary.put(dateKey, dayData);
            }

            return new ArrayList<>(dailySummary.values());

        } catch (Exception e) {
            System.err.println("🚨 เกิดข้อผิดพลาดในการดึงรายงานรายได้ร้านค้า: " + e.getMessage());
            return List.of();
        }
    }

    // 🎯 cron = "0 * * * * *" หมายถึงให้ฟังก์ชันนี้ทำงานทุกๆ ต้นนาที (เช่น 12:00:00, 12:01:00)
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoCancelExpiredOrders() {

        // 1. กำหนดจุดตัดเวลา (เวลาปัจจุบัน ถอยหลังไป 15 นาที)
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(10);

        // 2. ไปดึงออเดอร์จาก DB (สมมติว่าสถานะรอไรเดอร์คือ "WAITING_RIDER")
        List<Order> expiredOrders = orderRepo.findExpiredOrders("WaitingRider", cutoffTime);

        // 3. ถ้าเจอออเดอร์ที่หมดอายุ ให้วนลูปเปลี่ยนสถานะ
        if (!expiredOrders.isEmpty()) {
            for (Order order : expiredOrders) {
                order.setOrderstatus("cancel");
                order.setCanceldetail("ยกเลิกคำสั่งซื้อ เนื่องจากไม่มีผู้จัดส่งรับงานภายใน 10 นาที");

                System.out.println("-- Auto-canceled Order ID: " + order.getOrderid());
            }

            // 4. บันทึกการเปลี่ยนแปลงทั้งหมดกลับลง Database ทีเดียว
            orderRepo.saveAll(expiredOrders);
            System.out.println("เคลียร์ออเดอร์หมดอายุอัตโนมัติจำนวน " + expiredOrders.size() + " รายการ");
        }
    }

    // cron = "0 * * * * *" ฟังก์ชันนี้ทำงานทุกๆ 1 นาที
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoRejectExpiredRestaurantOrders() {

        // กำหนดจุดตัดเวลา (เวลาปัจจุบัน ถอยหลังไป 10 นาที)
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(10);

        // ไปดึงออเดอร์จาก DB ที่รอร้านค้ารับ ("WaitingRestaurant") และเวลาสั่งซื้อเกิน 10 นาที
        List<Order> expiredOrders = orderRepo.findExpiredOrders("WaitingRestaurant", cutoffTime);

        // 3. ถ้าเจอออเดอร์ที่หมดเวลา ให้วนลูปเปลี่ยนสถานะ
        if (!expiredOrders.isEmpty()) {
            for (Order order : expiredOrders) {
                // เปลี่ยนสถานะเป็น reject (ร้านค้าปฏิเสธ/ไม่รับออเดอร์)
                order.setOrderstatus("reject");
                order.setCanceldetail("ยกเลิกอัตโนมัติ: ร้านค้าไม่ได้กดรับออเดอร์ภายใน 10 นาที");

                System.out.println("-- Auto-rejected Order ID (Restaurant Timeout): " + order.getOrderid());
            }

            // 4. บันทึกการเปลี่ยนแปลงทั้งหมดกลับลง Database ทีเดียว
            orderRepo.saveAll(expiredOrders);
            System.out.println("เคลียร์ออเดอร์ร้านค้าไม่กดรับอัตโนมัติจำนวน " + expiredOrders.size() + " รายการ");
        }
    }
}