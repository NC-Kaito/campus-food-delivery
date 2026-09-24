package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailOptionDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.*;
import com.it22mjudelivery.springboot_api.v1.repositories.*;
import lombok.RequiredArgsConstructor;
import org.hibernate.Hibernate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepo;
    private final OrderDetailRepository orderDetailRepo;
    private final OrderDetailOptionRepository orderDetailOptionRepo;
    private final MemberRepository memberRepo;
    private final RestaurantRepository restaurantRepo;
    private final MenuRepository menuRepo;
    private final OptionRepository optionRepo;
    private final RiderRepository riderRepo;
    private final CloudinaryService cloudinaryService;

    @Override
    @Transactional
    public boolean memberConfirmOrder(AddOrderDto addOrderDto) {

        try {
            String memberUser = addOrderDto.getMemberUsername().trim();
            String restUser = addOrderDto.getRestaurantUsername().trim();

            System.out.println("🔍 กำลังค้นหาผู้ใช้: " + memberUser);
            Member member = memberRepo.findByUsername(memberUser)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้ใช้ยูสเซอร์เนม: " + memberUser));

            System.out.println("🔍 กำลังค้นหาร้านค้า: " + restUser);
            Restaurant restaurant = restaurantRepo.findByUsername(restUser)
                    .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านค้ายูสเซอร์เนม: " + restUser));

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

            // 2. บันทึกรายการอาหาร (OrderDetail)
            if (addOrderDto.getItems() != null) {
                for (AddOrderDetailDto detailDto : addOrderDto.getItems()) {

                    Menu menu = menuRepo.findById(detailDto.getMenuId())
                            .orElseThrow(() -> new RuntimeException(
                                    "เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัส Menu: " + detailDto.getMenuId()));

                    // Snapshot ชื่อเมนูและราคา ณ เวลาสั่ง
                    String resolvedMenuName = (detailDto.getMenuNameAtOrder() != null
                            && !detailDto.getMenuNameAtOrder().trim().isEmpty())
                            ? detailDto.getMenuNameAtOrder()
                            : menu.getMenuname();

                    double resolvedPrice = detailDto.getPriceAtOrder() > 0
                            ? detailDto.getPriceAtOrder()
                            : menu.getPrice();

                    OrderDetail orderDetail = OrderDetail.builder()
                            .menuNameAtOrder(resolvedMenuName)
                            .priceAtOrder(resolvedPrice)
                            .qty(detailDto.getQty())
                            .subtotal(detailDto.getSubTotal())
                            .note(detailDto.getNote())
                            .order(savedOrder)
                            .menu(menu)
                            .build();

                    OrderDetail savedOrderDetail = (OrderDetail) orderDetailRepo.save(orderDetail);

                    // 3. บันทึกตัวเลือกเสริม (Orderdetailoption)
                    if (detailDto.getAddons() != null) {
                        for (AddOrderDetailOptionDto optionDto : detailDto.getAddons()) {

                            Option option = (Option) optionRepo.findById(optionDto.getOptionId())
                                    .orElseThrow(() -> new RuntimeException(
                                            "เกิดข้อผิดพลาดที่ระบบ ไม่พบรหัส Option: " + optionDto.getOptionId()));

                            String resolvedOptionName = (optionDto.getOptionNameAtOrder() != null
                                    && !optionDto.getOptionNameAtOrder().trim().isEmpty())
                                    ? optionDto.getOptionNameAtOrder()
                                    : "ตัวเลือกเสริม";

                            double resolvedOptionPrice = optionDto.getPriceAtOrder() > 0
                                    ? optionDto.getPriceAtOrder()
                                    : option.getOptionprice();

                            Orderdetailoption orderDetailOption = Orderdetailoption.builder()
                                    .orderDetail(savedOrderDetail)
                                    .menuoptiondetail(option)
                                    .addonNameAtOrder(resolvedOptionName)
                                    .priceAtOrder(resolvedOptionPrice)
                                    .addon_qty(1)
                                    .build();

                            orderDetailOptionRepo.save(orderDetailOption);
                        }
                    }
                }
            }

            return true;

        } catch (Throwable e) {
            System.err.println("🚨 เกิดข้อผิดพลาดในระบบ Service: " + e.getMessage());
            e.printStackTrace();
            TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
            return false;
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Order> getOrdersByMember(String username) {
        System.out.println("📦 [SERVICE] กำลังดึงประวัติคำสั่งซื้อของกลุ่มสมาชิก: " + username);
        try {
            List<Order> orders = orderRepo.findOrdersByMemberUsername(username.trim());

            for (Order order : orders) {
                if (order.getOrderDetails() != null) {
                    for (OrderDetail detail : order.getOrderDetails()) {
                        Hibernate.initialize(detail.getOrderDetailOptions());
                    }
                }
            }

            return orders;
        } catch (Exception e) {
            System.err.println("🚨 เกิดข้อผิดพลาดในการดึงประวัติออเดอร์ที่ Service: " + e.getMessage());
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
                imageUrl = cloudinaryService.uploadImage(issueImage, "maejo_delivery/issues");
            }

            order.setCanceldetail(issueDetail);

            if (!imageUrl.isEmpty()) {
                order.setCancelimage(imageUrl);
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
            return orderRepo.findByOrderstatusOrderByOrderidDesc("WaitingRider");
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getActiveOrdersByRider(String username) {
        try {
            List<String> activeOrderStatus = Arrays.asList("WaitingRestaurant", "goingToRestaurant", "delivery", "arrived");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, activeOrderStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public boolean doConfirmOrderByRider(String studentId, int orderId) {
        try {
            Rider rider = riderRepo.findByStudentid(studentId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบชื่อผู้ใช้งาน"));

            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อในระบบ"));

            order.setRider(rider);
            order.setOrderstatus("WaitingRestaurant");
            order.setPickuptime(LocalTime.now());
            orderRepo.save(order);
            return true;
        } catch (Exception e) {
            System.err.println("🚨 Error doConfirmOrderByRider: " + e.getMessage());
            return false;
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getRiderIncomeByDateRange(String studentId, LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Order> orders = orderRepo.findRiderSuccessOrdersByDateRange(studentId, startDate, endDate);

            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            Map<String, Map<String, Object>> dailySummary = new LinkedHashMap<>();

            for (Order order : orders) {
                String dateKey = order.getOrderdate().format(formatter);
                Map<String, Object> dayData = dailySummary.getOrDefault(dateKey, new LinkedHashMap<>());

                int currentRounds = (int) dayData.getOrDefault("rounds", 0);
                double currentIncome = (double) dayData.getOrDefault("amount", 0.0);
                double deliveryFee = order.getDelivery_fee();

                dayData.put("date", dateKey);
                dayData.put("rounds", currentRounds + 1);
                dayData.put("amount", currentIncome + deliveryFee);

                dailySummary.put(dateKey, dayData);
            }

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
            List<String> status = Arrays.asList("WaitingRestaurant");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, status);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getOrdersNotifyByRider(String username) {
        try {
            List<String> status = Arrays.asList("WaitingRider", "delivery");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, status);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รอไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public boolean doConfirmOrderByRestaurant(int orderId) {
        try {
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบรายการคำสั่งซื้อในระบบ"));

            order.setOrderstatus("delivery");
            orderRepo.save(order);
            return true;
        } catch (Exception e) {
            System.err.println("🚨 Error confirmOrderByRestaurant: " + e.getMessage());
            return false;
        }
    }

    @Override
    public List<Order> getActiveOrdersByRestaurant(String username) {
        try {
            List<String> activeOrderStatus = Arrays.asList("goingToRestaurant", "delivery");
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
    public List<Order> getSuccessOrdersByRestaurant(String username) {
        try {
            List<String> successStatus = Arrays.asList("delivered", "Success", "success", "completed");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, successStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่สำเร็จแล้วของร้านค้าได้: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    public boolean updateOrderSuccess(int orderId, String newStatus) {
        return updateOrderStatus(orderId, newStatus);
    }

    @Override
    @Transactional
    public boolean updateOrderStatus(int orderId, String newStatus) {
        try {
            Order order = orderRepo.findById(orderId)
                    .orElseThrow(() -> new RuntimeException("เกิดข้อผิดพลาด ไม่พบคำสั่งซื้อรหัส: " + orderId));

            if (newStatus.equalsIgnoreCase("success")) {
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
    public List<Order> getSuccessOrdersByRider(String username) {
        try {
            List<String> successStatus = Arrays.asList("delivered", "Success", "success", "reviewSuccess");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, successStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่สำเร็จแล้วได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getCancelOrdersByRider(String username) {
        try {
            List<String> cancelStatus = Arrays.asList("cancel", "cancelled", "issue_reported", "reject");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(username, cancelStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่ถูกยกเลิกของไรเดอร์ได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getReviewSuccessOrders(String studentId) {
        try {
            List<String> reviewStatus = Arrays.asList("reviewSuccess");
            return orderRepo.findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(studentId, reviewStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รีวิวแล้วได้: " + e.getMessage());
        }
    }

    @Override
    public List<Order> getReviewSuccessOrdersByRestaurant(String username) {
        try {
            List<String> reviewStatus = Arrays.asList("reviewSuccess");
            return orderRepo.findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(username, reviewStatus);
        } catch (Exception e) {
            throw new RuntimeException("ไม่สามารถดึงข้อมูลออเดอร์ที่รีวิวแล้วของร้านค้าได้: " + e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getRestaurantIncomeByDateRange(String username, LocalDateTime startDate, LocalDateTime endDate) {
        try {
            List<Order> orders = orderRepo.findRestaurantSuccessOrdersByDateRange(username, startDate, endDate);

            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
            Map<String, Map<String, Object>> dailySummary = new LinkedHashMap<>();

            for (Order order : orders) {
                String dateKey = order.getOrderdate().format(formatter);
                Map<String, Object> dayData = dailySummary.getOrDefault(dateKey, new LinkedHashMap<>());

                int currentOrdersCount = (int) dayData.getOrDefault("rounds", 0);
                double currentIncome = (double) dayData.getOrDefault("amount", 0.0);
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

    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoCancelExpiredOrders() {
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(10);
        List<Order> expiredOrders = orderRepo.findExpiredOrders("WaitingRider", cutoffTime);

        if (!expiredOrders.isEmpty()) {
            for (Order order : expiredOrders) {
                order.setOrderstatus("cancel");
                order.setCanceldetail("ยกเลิกคำสั่งซื้อ เนื่องจากไม่มีผู้จัดส่งรับงานภายใน 10 นาที");
            }
            orderRepo.saveAll(expiredOrders);
            System.out.println("เคลียร์ออเดอร์หมดอายุอัตโนมัติจำนวน " + expiredOrders.size() + " รายการ");
        }
    }

    @Scheduled(cron = "0 * * * * *")
    @Transactional
    public void autoRejectExpiredRestaurantOrders() {
        LocalDateTime cutoffTime = LocalDateTime.now().minusMinutes(10);
        List<Order> expiredOrders = orderRepo.findExpiredOrders("WaitingRestaurant", cutoffTime);

        if (!expiredOrders.isEmpty()) {
            for (Order order : expiredOrders) {
                order.setOrderstatus("reject");
                order.setCanceldetail("ยกเลิกอัตโนมัติ: ร้านค้าไม่ได้กดรับออเดอร์ภายใน 10 นาที");
            }
            orderRepo.saveAll(expiredOrders);
            System.out.println("เคลียร์ออเดอร์ร้านค้าไม่กดรับอัตโนมัติจำนวน " + expiredOrders.size() + " รายการ");
        }
    }
}