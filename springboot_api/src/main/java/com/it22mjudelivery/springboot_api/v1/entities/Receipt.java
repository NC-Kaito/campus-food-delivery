package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name="receipt")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Receipt {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int receiptid;

    @Column(nullable = false)
    private LocalDateTime receiptdate;

    @Column(nullable = false)
    private double totalamount;

    @Column
    private double receiptImg;

//    @OneToOne(fetch = FetchType.LAZY)
//    @JoinColumn(name = "paymentServiceId", nullable = false)
//    private PaymentService paymentservice;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "orderId", nullable = false)
    private Order order;
}
