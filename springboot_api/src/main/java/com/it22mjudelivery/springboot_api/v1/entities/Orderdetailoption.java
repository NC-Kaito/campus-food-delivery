package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.util.Objects;

@Entity
@Table(name="orderdetailoption")
@IdClass(OrderdetailoptionId.class)
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderDetail", "menuaddondetail"})
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Orderdetailoption {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderdetailid", nullable = false)
    @JsonIgnore
    private OrderDetail orderDetail;

    @Id
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "optiondetailid", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Option menuoptiondetail;

    @Column(nullable = false)
    private String addonNameAtOrder;

    @Column(nullable = false)
    private double priceAtOrder;

    @Column(nullable = true)
    private Integer addon_qty;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Orderdetailoption)) return false;
        Orderdetailoption that = (Orderdetailoption) o;
        return Objects.equals(orderDetail, that.orderDetail) &&
                Objects.equals(menuoptiondetail, that.menuoptiondetail);
    }

    @Override
    public int hashCode() {
        return Objects.hash(orderDetail, menuoptiondetail);
    }
}