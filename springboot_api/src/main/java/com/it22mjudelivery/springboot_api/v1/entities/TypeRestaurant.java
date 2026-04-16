package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="typerestaurant")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class TypeRestaurant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int typerestaurantId;

    @Column(length = 50, nullable = false)
    private String typerestaurantName;
}
