package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
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
public class Orderdetailaddon {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore // 🎯 พระเอกของเรา! ตัดวงจรไม่ให้ Jackson แปลงข้อมูลย้อนกลับไปหาจานอาหาร
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addondetailid", nullable = false)
    private Menuaddondetail menuaddondetail;

    @Column
    private double priceAtOrder;

    @Column
    private int qtyaddon;
}