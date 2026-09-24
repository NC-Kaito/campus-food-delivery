package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.TypeRestaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TypeRestaurantRepository extends JpaRepository<TypeRestaurant, Integer> {
    Optional<TypeRestaurant> findById(Integer typerestaurantId);
}
