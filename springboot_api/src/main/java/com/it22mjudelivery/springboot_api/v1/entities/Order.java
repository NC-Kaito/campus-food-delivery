package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Entity
@Table(name="orders")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int orderid;

    @Column(nullable = true)
    private LocalDateTime orderdate;

    @Column
    private LocalTime pickuptime;

    @Column
    private LocalTime successtime;

    @Column(nullable = false)
    private double delivery_fee;

    @Column(nullable = false)
    private double totalprice;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(length = 255,nullable = false)
    private String addressdetail;

    @Column
    private String pickupimage;

    @Column(nullable = false)
    private String orderstatus;

    @Column(length = 100)
    private String canceldetail;

    @Column
    private String cancelimage;

    @ManyToOne
    @JoinColumn(name = "memberId", nullable = false)
    @JsonIgnoreProperties({"orders", "hibernateLazyInitializer", "handler"})
    private Member member;

    @ManyToOne
    @JoinColumn(name = "riderId", nullable = true)
    @JsonIgnoreProperties({"orders", "hibernateLazyInitializer", "handler"})
    private Rider rider;

    @ManyToOne
    @JoinColumn(name = "restaurantId", nullable = false)
    @JsonIgnoreProperties({"orders", "menus", "openingHours", "hibernateLazyInitializer", "handler"})
    private Restaurant restaurant;

    @OneToMany(mappedBy = "order" , cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<Notification> notifications;

    // 🎯 แก้ไขบรรทัดนี้: เปลี่ยน FetchType.LAZY -> FetchType.EAGER
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @JsonIgnoreProperties({"order", "hibernateLazyInitializer", "handler"})
    private List<OrderDetail> orderDetails;
}