package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.Set;

@Entity
@Table(name = "menu")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true) // ← เปลี่ยนจาก @Data กัน equals/hashCode วนลูปกับความสัมพันธ์
public class Menu {

    @Id
    @EqualsAndHashCode.Include // ← ใช้แค่ id ในการเทียบ equals/hashCode
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int menuid;

    @Column(nullable = false)
    private String menuname;

    @Column(nullable = false)
    private String description;

    @Column(nullable = false)
    private String imageurl;

    @Column(nullable = false)
    private double price;

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