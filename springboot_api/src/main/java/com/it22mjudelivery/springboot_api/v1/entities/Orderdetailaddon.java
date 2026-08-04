package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.Objects;

@Entity
@Table(name="orderdetailaddon")
@IdClass(OrderdetailaddonId.class)
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderDetail", "menuaddondetail"})
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Orderdetailaddon {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "addondetailid", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Menuaddondetail menuaddondetail;

    private double priceAtOrder;

    @Column(nullable = true)
    private Integer addon_qty;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Orderdetailaddon)) return false;
        Orderdetailaddon that = (Orderdetailaddon) o;
        return Objects.equals(orderDetail, that.orderDetail) &&
                Objects.equals(menuaddondetail, that.menuaddondetail);
    }

    @Override
    public int hashCode() {
        return Objects.hash(orderDetail, menuaddondetail);
    }
}