package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name="orderdetail")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OrderDetail {

    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    private Integer orderdetailid;

    @Column(nullable = false)
    private int qty;

    @Column(nullable = false)
    private double subtotal;

    @Column
    private String note;

    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne
    @JoinColumn(name = "menu_id", nullable = false)
    private Menu menu;

    @ManyToMany(cascade = {CascadeType.ALL})
    @JoinTable(
            name="orderdetail_addon",
            joinColumns = @JoinColumn(name = "orderdetailid"),
            inverseJoinColumns = @JoinColumn(name = "addondetailid")
    )
    private Set<Menuaddondetail> menuaddondetails = new HashSet<>();

}

