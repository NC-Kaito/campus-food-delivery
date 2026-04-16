package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name="notification")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int notificationid;

    @Column(length = 100, nullable = false)
    private String message;

    @Column(nullable = false)
    private LocalDateTime createat;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name="riderId")
    private Rider rider;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name="orderId")
    private Order order;
}
