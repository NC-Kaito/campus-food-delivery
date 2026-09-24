package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Integer> {
    Optional<Review> findByOrder_Orderid(int orderid);
    boolean existsByOrder_Orderid(int orderid);

}