package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Entity
@Table(name="Menuaddongroup")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Menuaddongroup {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int addongroupid;

    @Column(length = 50, nullable = false)
    private String addongroupname;

    @Column(nullable = false)
    private boolean isRequired;

    @Column(nullable = false)
    private int maxselect;

    @Column(nullable = false)
    private boolean status;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menuid", nullable = false)
    private Menu menu;

    @OneToMany(mappedBy = "menuaddongroup", fetch = FetchType.EAGER)
    private List<Menuaddondetail> menuaddondetails;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "username", nullable = false)
    private Restaurant username;

}