package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    List<Restaurant> findByRestaurantnameContainingIgnoreCaseAndVerificationstatusTrue(String restaurantname);

    @Query("SELECT DISTINCT r FROM Menu m " +
            "JOIN m.restaurant r " +
            "WHERE (LOWER(r.restaurantname) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
            "OR LOWER(m.menuname) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "AND r.verificationstatus = :status")
    List<Restaurant> searchByStoreOrMenu(@Param("keyword") String keyword, @Param("status") String status);
}
