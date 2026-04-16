package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="faculty")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Faculty {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int facultyid;

    @Column(length = 100, nullable = false)
    private String facultyname;
}
