package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.Set;

@Entity
@Table(name = "Menuaddongroup")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true) // ← เปลี่ยนจาก @Data เช่นกัน
public class Menuaddongroup {

    @Id
    @EqualsAndHashCode.Include // ← ใช้แค่ id ในการเทียบ equals/hashCode
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int addongroupid;

    @Column(length = 50, nullable = false)
    private String addongroupname;

    @Column(nullable = false)
    private boolean isRequired;

    @Column(nullable = false)
    private int maxselect;

    @Column
    private boolean status;

    @ManyToMany(mappedBy = "menuAddonGroups")
    @JsonIgnore
    private Set<Menu> menus;

    @OneToMany(mappedBy = "menuaddongroup", fetch = FetchType.EAGER)
    private List<Menuaddondetail> menuaddondetails;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "username", nullable = false)
    private Restaurant username;
}