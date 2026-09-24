package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.Menu;
import com.it22mjudelivery.springboot_api.v2.entities.OrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, Integer> {
    List<OrderDetail> findByMenu(Menu menu);
}
