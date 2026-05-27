package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantRepository  extends JpaRepository<Restaurant, String> {
    boolean existsByUsername(String username);

    Optional<Restaurant> findByUsername(String username);

    //-----Admin------
    List<Restaurant> findByVerificationstatus(String status);
    long countByVerificationstatus(String verificationStatus);

    List<Restaurant> findByRestaurantnameContainingIgnoreCaseAndVerificationstatus(String name, String status);
}
