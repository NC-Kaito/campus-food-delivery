package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {
}
