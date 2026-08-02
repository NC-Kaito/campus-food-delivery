package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalTime;

@Entity
    @Table(name = "Restaurantopendate")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Restaurantopendate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private DayOfWeek dayOfWeek; // MONDAY, TUESDAY, ... SUNDAY

    @Column(nullable = false)
    private LocalTime opentime;

    @Column(nullable = false)
    private LocalTime closetime;

    @JsonProperty("open")
    @Column(nullable = false)
    private boolean open;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_username", nullable = false)
    @JsonIgnore
    private Restaurant restaurant;
}