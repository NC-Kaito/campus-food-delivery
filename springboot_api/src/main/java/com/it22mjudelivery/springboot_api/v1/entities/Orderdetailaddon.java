package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name="orderdetailaddon")
@IdClass(OrderdetailaddonId.class)
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderDetail", "menuaddondetail"})
@EqualsAndHashCode(exclude = {"orderDetail", "menuaddondetail"})
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Orderdetailaddon {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore
    private OrderDetail orderDetail;

    // 🎯 แก้ไขบรรทัดนี้: เปลี่ยน FetchType.LAZY -> FetchType.EAGER
    @Id
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "addondetailid", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Menuaddondetail menuaddondetail;

    private double priceAtOrder;

    @Column(nullable = true)
    private Integer addon_qty;
}