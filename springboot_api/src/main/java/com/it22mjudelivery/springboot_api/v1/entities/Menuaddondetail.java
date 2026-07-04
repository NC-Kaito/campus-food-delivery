package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
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

    @Column(nullable = false)
    private boolean status;

    @JsonIgnore
    @OneToMany(mappedBy = "menuaddondetail", fetch = FetchType.LAZY)
    @Builder.Default
    private Set<Orderdetailaddon> orderdetailaddons = new HashSet<>();

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addongroupid", nullable = false)
    private Menuaddongroup menuaddongroup;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "addonid", nullable = false)
    private Addonmenu addonmenu;

}
