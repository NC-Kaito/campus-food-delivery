package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TypeMenuRepository extends JpaRepository<TypeMenu, Integer> {
    Optional<TypeMenu> findById(Integer typemenuId);
}
