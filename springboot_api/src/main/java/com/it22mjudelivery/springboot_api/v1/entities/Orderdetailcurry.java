package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name="orderdetailcurry")
@IdClass(OrderdetailcurryId.class) // ใช้ Composite Key
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderDetail", "menu"})
@EqualsAndHashCode(exclude = {"orderDetail", "menu"})
public class Orderdetailcurry {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore // ตัดวงจร Infinite Loop ตอนแปลง JSON
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menu_id", nullable = false) // วิ่งไปชี้ menuid ในตาราง Menu ตรงๆ
    private Menu menu;

    @Column(nullable = false)
    private double priceAtOrder; // ล็อกราคากับข้าวราดหน้า ณ ตอนที่สั่ง (เช่น จานแรกราดฟรี/คิดรวม หรือตักละ 5 บาท)
}