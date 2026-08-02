package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name="orderdetail")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class OrderDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer orderdetailid;

    @Column(nullable = false)
    private int qty;

    @Column(nullable = false)
    private double subtotal;

    @Column
    private String note;

    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    @JsonIgnore
    private Order order;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "menu_id", nullable = false)
    @JsonIgnoreProperties({"restaurant", "hibernateLazyInitializer", "handler"})
    private Menu menu;

    // 🎯 แก้ไข: กำหนด FetchType.EAGER ป้องกัน Proxy สะดุด
    @OneToMany(mappedBy = "orderDetail", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @JsonIgnoreProperties({"orderDetail", "hibernateLazyInitializer", "handler"})
    @Builder.Default
    private Set<Orderdetailaddon> orderDetailAddons = new HashSet<>();

    // 🎯 แก้ไข: กำหนด FetchType.EAGER ป้องกัน Proxy สะดุด
    @OneToMany(mappedBy = "orderDetail", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @JsonIgnoreProperties({"orderDetail", "hibernateLazyInitializer", "handler"})
    @Builder.Default
    private Set<Orderdetailcurry> orderDetailCurries = new HashSet<>();
}