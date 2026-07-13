package com.it22mjudelivery.springboot_api.v1.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalTime;

@Entity
    @Table(name = "restaurantopeninghour")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Restaurantopeninghour {

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

    @Column(nullable = false)
    private boolean closed; // true = วันนี้ร้านปิดทั้งวัน (ไม่ต้องดู opentime/closetime)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_username", nullable = false)
    @JsonIgnore
    private Restaurant restaurant;
}