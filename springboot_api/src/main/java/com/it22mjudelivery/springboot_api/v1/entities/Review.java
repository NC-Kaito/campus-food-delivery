package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name="review")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Review {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int reviewid;

    @Column(nullable = false)
    private LocalDateTime reviewdate;

    @Column(nullable = false)
    private int restaurantrating;

    @Column(nullable = false)
    private int riderrating;

    @Column(length = 255,nullable = true)
    private String commentrestaurant;

    @Column(nullable = true)
    private boolean cleanliness;

    @Column(nullable = true)
    private boolean taste_rating;

    @Column(nullable = true)
    private boolean delivery_speed;

    @Column(nullable = true)
    private boolean food_condition;

    @Column(length = 255, nullable = true)
    private String commentrider;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderId", nullable = false)
    private Order order;
}
