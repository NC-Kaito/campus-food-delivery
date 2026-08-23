package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Integer> {
    @Query("SELECT DISTINCT o FROM Order o " +
            "LEFT JOIN FETCH o.orderDetails d " +
//            "LEFT JOIN FETCH d.orderDetailAddons " +
            "WHERE o.member.username = :username " +
            "ORDER BY o.orderid DESC")
    List<Order> findOrdersByMemberUsername(@Param("username") String username);

    List<Order> findByOrderstatusOrderByOrderidDesc(String orderstatus);

    List<Order> findByRider_StudentidAndOrderstatusInOrderByOrderidDesc(String username, List<String> status);

    List<Order> findByRestaurant_UsernameAndOrderstatusInOrderByOrderidDesc(String username, List<String> status);

    @Query("SELECT o FROM Order o WHERE o.orderstatus = :status AND o.orderdate <= :cutoffTime")
    List<Order> findExpiredOrders(@Param("status") String status, @Param("cutoffTime") LocalDateTime cutoffTime);
}
