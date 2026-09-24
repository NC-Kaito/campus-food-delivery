package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.Admin;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AdminRepository extends JpaRepository<Admin, String> {
    Optional<Admin> findByUsername(String username);
}
