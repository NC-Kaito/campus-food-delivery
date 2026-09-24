package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.TypeMenu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TypeMenuRepository extends JpaRepository<TypeMenu, Integer> {
    Optional<TypeMenu> findById(Integer typemenuId);

    Optional<TypeMenu> findByTypemenuName(String typemenuName);
}
