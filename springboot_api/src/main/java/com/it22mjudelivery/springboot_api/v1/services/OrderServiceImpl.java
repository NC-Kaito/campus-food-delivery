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

                    OrderDetail orderDetail = OrderDetail.builder()
                            .qty(detailDto.getQty())
                            .subtotal(detailDto.getSubTotal())
                            .note(detailDto.getNote())
                            .order(savedOrder)
                            .menu(menu)
                            .build();

                    OrderDetail savdOrderDetail = orderDetailRepo.save(orderDetail);

                    // 3. วนลูปแกะรายการท็อปปิ้งเสริม (Orderdetailaddon) ที่ผูกอยู่กับจานอาหารรอบนั้นๆ
                    if (detailDto.getAddons() != null) {
                        for (AddOrderDetailAddOnDto addOnDto : detailDto.getAddons()) {

                            Menuaddondetail menuaddondetail = menuaddondetailRepo.findById(addOnDto.getAddondetailid())
                                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัสAddOn"));

                            Orderdetailaddon orderdetailaddon = Orderdetailaddon.builder()
                                    .orderDetail(savdOrderDetail)
                                    .menuaddondetail(menuaddondetail)
                                    .priceAtOrder(menuaddondetail.getAddonprice())
                                    .addon_qty(addOnDto.getAddon_qty())
                                    .build();

                            orderDetailAddonRepo.save(orderdetailaddon);
                        }
                    }

                    // 🎯 4. (เพิ่มใหม่) วนลูปแกะรายการกับข้าวราดแกง (Orderdetailcurry)
                    //    เมนูทั่วไปที่ไม่มีกับข้าว list นี้จะเป็น null/ว่าง โค้ดจะข้ามไปเฉยๆ ไม่กระทบ
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
            // 1. ค้นหาออเดอร์ในระบบ
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            // 2. อัปโหลดรูปลง Cloudinary (ถ้ามีการแนบรูปมาด้วย)
            String imageUrl = "";
            if (issueImage != null && !issueImage.isEmpty()) {
                // ⚠️ คำเตือน: ตรงนี้ให้เรียกใช้ Service อัปโหลดรูปภาพของคุณ
                // สมมติว่ามี CloudinaryService อยู่แล้ว และโยนเข้าโฟลเดอร์ maejo_delivery/issues
                // imageUrl = cloudinaryService.uploadImage(issueImage, "maejo_delivery/issues");

                // *ตัวอย่างโค้ดถ้าคุณใช้ Cloudinary แบบเดิม:
                // Map uploadResult = cloudinary.uploader().upload(issueImage.getBytes(), ObjectUtils.asMap("folder", "maejo_delivery/issues"));
                // imageUrl = uploadResult.get("url").toString();
            }

            // 3. บันทึกข้อมูลการแจ้งปัญหาลง Entity
            order.setCanceldetail(issueDetail); // เก็บรายละเอียดปัญหา

            if (!imageUrl.isEmpty()) {
                order.setCancelimage(imageUrl); // เก็บ URL รูปหลักฐาน
            }

            // 4. เปลี่ยนสถานะให้ตรงกับที่แอป Flutter ดักไว้
            order.setOrderstatus("issue_reported");

            orderRepo.save(order);
            System.out.println("✅ บันทึกข้อมูลการแจ้งปัญหาสำหรับออเดอร์รหัส " + orderId + " สำเร็จ!");

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
    @Transactional
    public boolean updateOrderStatus(int orderId, String newStatus) {
        try {
            // ค้นหาออเดอร์จาก Database
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            // อัปเดตสถานะใหม่
            if(newStatus.equalsIgnoreCase("Success")){
                order.setSuccesstime(LocalTime.now());
            }
            order.setOrderstatus(newStatus);
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
            List<String> successStatus = Arrays.asList("delivered", "Success");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, successStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่สำเร็จแล้วได้: " + e.getMessage());
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

    // 🎯 cron = "0 * * * * *" หมายถึงให้ฟังก์ชันนี้ทำงานทุกๆ ต้นนาที (เช่น 12:00:00, 12:01:00)
    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoCancelExpiredOrders() {

        // 1. กำหนดจุดตัดเวลา (เวลาปัจจุบัน ถอยหลังไป 15 นาที)
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(15);

        // 2. ไปดึงออเดอร์จาก DB (สมมติว่าสถานะรอไรเดอร์คือ "WAITING_RIDER")
        List<Order> expiredOrders = orderRepo.findExpiredOrders("WaitingRider", cutoffTime);

        // 3. ถ้าเจอออเดอร์ที่หมดอายุ ให้วนลูปเปลี่ยนสถานะ
        if (!expiredOrders.isEmpty()) {
            for (Order order : expiredOrders) {
                order.setOrderstatus("cancel");
                order.setCanceldetail("ไม่มีผู้จัดส่งรับงานภายใน 15 นาที");

                System.out.println("-- Auto-canceled Order ID: " + order.getOrderid());
            }

            // 4. บันทึกการเปลี่ยนแปลงทั้งหมดกลับลง Database ทีเดียว
            orderRepo.saveAll(expiredOrders);
            System.out.println("✅ เคลียร์ออเดอร์หมดอายุอัตโนมัติจำนวน " + expiredOrders.size() + " รายการ");
        }
    }
}