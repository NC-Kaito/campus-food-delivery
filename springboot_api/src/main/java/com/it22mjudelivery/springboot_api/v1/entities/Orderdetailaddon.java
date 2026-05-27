package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="orderdetailaddon")

@IdClass(OrderdetailaddonId.class)

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Orderdetailaddon {
    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addondetailid", nullable = false)
    private Menuaddondetail menuaddondetail;

    private double priceAtOrder;

}
