package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name="orderdetailcurry")
@IdClass(OrderdetailcurryId.class)
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderDetail", "menu"})
@EqualsAndHashCode(exclude = {"orderDetail"})
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"}) // 🎯 เพิ่มบรรทัดนี้กันเหนียว
public class Orderdetailcurry {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.EAGER) // 🎯 เปลี่ยนเป็น EAGER เพื่อดึงข้อมูลรูปกับชื่อเมนูกับข้าวทันที
    @JoinColumn(name = "menu_id", nullable = false)
    @JsonIgnoreProperties({"restaurant", "hibernateLazyInitializer", "handler"}) // 🎯 เพิ่มการละเว้นไม่ให้ลูป
    private Menu menu;

    @Column(nullable = false)
    private double priceAtOrder;
}