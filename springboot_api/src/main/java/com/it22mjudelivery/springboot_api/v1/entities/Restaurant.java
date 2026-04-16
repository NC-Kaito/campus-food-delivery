package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Date;

@Entity
@Table(name="restaurant")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Restaurant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int restaurantid;

    @Column(length = 20, nullable = false, unique = true)
    private String username;

    @Column(length = 20, nullable = false)
    private String password;

    @Column(length = 50, nullable = false)
    private String restaurantname;

    @Column(length = 200, nullable = false)
    private String restaurantimage;

    @Column(nullable = false)
    private LocalTime opentime;

    @Column(nullable = false)
    private LocalTime closetime;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(length = 200, nullable = false)
    private String lease_agreement_img;

    @Column(length = 50, nullable = false)
    private String ownerfirstname;

    @Column(length = 50, nullable = false)
    private String ownerlastname;

    @Column(length = 100, nullable = false, unique = true)
    private String email;

    @Column(length = 15, nullable = false)
    private String phone;

    @Column(nullable = false)
    private boolean statusopen;

    @Column(nullable = false)
    private LocalDateTime registerdate;

    @Column(nullable = false)
    private boolean verificationstatus;

    @Column(length = 100)
    private String notapprovedetail;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "typerestaurantId", nullable = false)
    private TypeRestaurant typerestaurant;
}
