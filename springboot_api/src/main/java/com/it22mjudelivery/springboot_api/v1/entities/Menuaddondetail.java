package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name="Menuaddnodetail")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@ToString(exclude = {"orderdetailaddons", "menuaddongroup", "addonmenu"})
public class Menuaddondetail {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int addondetailid;

    @Column(nullable = false)
    private double addonprice;

    @Column
    private boolean status;

    @Column
    private boolean allowqtystatus;

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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Menuaddondetail)) return false;
        Menuaddondetail that = (Menuaddondetail) o;
        return addondetailid == that.addondetailid;
    }

    @Override
    public int hashCode() {
        return Integer.hashCode(addondetailid);
    }
}