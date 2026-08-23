package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Entity
@Table(name="restaurant")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Restaurant {

    @Id
    @Column(length = 20, nullable = false)
    private String username;

    @Column(length = 20, nullable = false)
    private String password;

    @Column(length = 50, nullable = false)
    private String restaurantname;

    @Column(length = 255, nullable = false)
    private String restaurantimage;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(length = 50, nullable = false)
    private String ownerfirstname;

    @Column(length = 50, nullable = false)
    private String ownerlastname;

    @Column(length = 255, nullable = false)
    private String imagecardid;

    @Column(length = 100, nullable = false, unique = true)
    private String email;

    @Column(length = 15, nullable = false)
    private String phone;

    @Column(nullable = false)
    private boolean statusopen;

    @Column(nullable = false)
    private LocalDateTime registerdate;

    @Column(nullable = false, length = 10)
    private String verificationstatus;

    @Column(length = 100)
    private String notapprovedetail;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "typerestaurantId", nullable = false)
    private TypeRestaurant typerestaurant;

    @OneToMany(mappedBy = "restaurant", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @Builder.Default
    private List<Restaurantopendate> openingHours = new ArrayList<>();


}
