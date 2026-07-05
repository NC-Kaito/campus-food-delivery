package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;

@Entity
@Table(name="menu")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Menu {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    private int menuid;

    @Column(nullable = false)
    private String menuname;

    @Column(nullable = false)
    private String description;

    @Column(nullable = false)
    private String imageurl;

    @Column(nullable = false)
    private double price;

    @Column(nullable = true)
    private double extraprice;

    @Column(nullable = false)
    private boolean status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurantId", nullable = false)
    private Restaurant restaurant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "typeMenuId", nullable = false)
    private TypeMenu typemenu;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "menu_addongroups", // ชื่อตารางกลาง
            joinColumns = @JoinColumn(name = "menu_id"),
            inverseJoinColumns = @JoinColumn(name = "addongroup_id")
    )
    @JsonIgnore // 🛑 ป้องกันไม่ให้ JSON ดึงค่าวนลูปกลับไปมา
    private Set<Menuaddongroup> menuAddonGroups;
}
