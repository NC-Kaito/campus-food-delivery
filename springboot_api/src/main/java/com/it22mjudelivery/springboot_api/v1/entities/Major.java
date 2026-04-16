package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name="major")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Major {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int majorid;

    @Column(length = 100, nullable = false)
    private String majorname;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "facultyid", nullable = false)
    private Faculty faculty;
}
