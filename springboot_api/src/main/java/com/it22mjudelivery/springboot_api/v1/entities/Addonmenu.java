package com.it22mjudelivery.springboot_api.v1.entities;


import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="Addonmenu")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Addonmenu {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int addonid;

    @Column(nullable = false , length = 30)
    private String addonname;
}
