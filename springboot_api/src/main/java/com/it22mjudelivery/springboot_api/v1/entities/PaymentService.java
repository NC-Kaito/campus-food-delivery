package com.it22mjudelivery.springboot_api.v1.entities;//package com.it22mjudelivery.campus_food_delivery.v1.entities;
//
//import jakarta.persistence.*;
//import lombok.AllArgsConstructor;
//import lombok.Builder;
//import lombok.Data;
//import lombok.NoArgsConstructor;
//
//import java.time.LocalDateTime;
//
//@Entity
//@Table(name="paymentservice")
//@Data
//@AllArgsConstructor
//@NoArgsConstructor
//@Builder
//public class PaymentService {
//    @Id
//    @GeneratedValue(strategy = GenerationType.IDENTITY)
//    private int paymentid;
//
//    @Column(nullable = false)
//    private LocalDateTime paymentdate;
//
//    @Column(nullable = false)
//    private double amount;
//
//    @Column(nullable = false)
//    private String paymentimage;
//
//    @Column(nullable = false)
//    private boolean approvalstatus;
//
//    @ManyToOne(fetch = FetchType.LAZY)
//    @JoinColumn(name="riderId", nullable = false)
//    private Rider rider;
//}
