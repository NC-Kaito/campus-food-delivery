package com.it22mjudelivery.springboot_api.v1.entities;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name= "member")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Member {
    @Id
    @Column(length = 20, nullable = false, unique = true)
    private String username;

    @Column(length = 20, nullable = false)
    private String password;

    @Column(length = 50, nullable = false)
    private String firstname;

    @Column(length = 50, nullable = false)
    private String lastname;

    @Column(length = 50, nullable = false, unique = true)
    private String email;

    @Column(length = 15, nullable = false)
    private String phone;

    @Column
    private String profileimg;

}
