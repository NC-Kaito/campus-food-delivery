// OrderdetailcurryRepository.java
package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Orderdetailcurry;
import com.it22mjudelivery.springboot_api.v1.entities.OrderdetailcurryId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderdetailcurryRepository
        extends JpaRepository<Orderdetailcurry, OrderdetailcurryId> {
}