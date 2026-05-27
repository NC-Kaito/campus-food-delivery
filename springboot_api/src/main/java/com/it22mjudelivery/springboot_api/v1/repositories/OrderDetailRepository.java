package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.OrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, Integer> {
}
