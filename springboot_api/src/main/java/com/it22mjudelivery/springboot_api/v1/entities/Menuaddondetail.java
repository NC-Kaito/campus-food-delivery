package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name="Menuaddnodetail")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Menuaddondetail {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int addondetailid;

    @Column(nullable = false)
    private double addonprice;

    @ManyToMany(mappedBy = "menuaddondetails")
    private Set<OrderDetail> orderDetails = new HashSet<>();


    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addongroupid", nullable = false)
    private Menuaddongroup menuaddongroup;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addonid", nullable = false)
    private Addonmenu addonmenu;

}
