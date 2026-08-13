package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;

@Entity
@Table(name="typemenu")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class TypeMenu {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int typemenuId;

    @Column(length = 50, nullable = false)
    private String typemenuName;

}
