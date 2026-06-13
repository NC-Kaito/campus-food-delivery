package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name="rider")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Rider {
    @Id
    private String studentid;

    @Column(length = 20, nullable = false)
    private String password;

    @Column(length = 50, nullable = false)
    private String firstName;

    @Column(length = 50, nullable = false)
    private String lastName;

    @Column(nullable = false)
    private LocalDate birthday;

    @Column(length = 100, nullable = false, unique = true)
    private String email;

    @Column(length = 15, nullable = false)
    private String phone;

    @Column(nullable = false)
    private String studentCard_Image;

    @Column(nullable = false)
    private String drivingLicenseImg;

    @Column(nullable = false)
    private String vehiclePlate;

    @Column(nullable = false)
    private String vehicle_Image;

    @Column(nullable = false)
    private boolean isActive;

    @Column(nullable = false, length = 10)
    private String verificationStatus;

    @Column(nullable = false)
    private LocalDateTime registerDate;

    @Column(length = 100)
    private String notApproveDetail;


    @Column(nullable = true)
    private LocalDate expiryDate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "majorId", nullable = false)
    private Major major;

    @OneToMany(mappedBy = "rider", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Notification> notifications;

//    @OneToMany(mappedBy = "rider" , cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<PaymentService> paymentServices;
}