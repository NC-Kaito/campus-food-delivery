package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="admin")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Admin {
    @Id
    @Column(length = 20, nullable = false, unique = true)
    private String username;

    @Column(length = 20, nullable = false)
    private String password;

    @Column(length = 50, nullable = false)
    private String firstname;

    @Column(length = 50, nullable = false)
    private String lastname;
}
