package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
    private String addongroupString;

    @Column(nullable = false)
    private boolean isRequired;

    @Column(nullable = false)
    private int maxselect;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menuid", nullable = false)
    private Menu menu;
}