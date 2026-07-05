package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Addonmenu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AddonmenuRepository extends JpaRepository<Addonmenu, Integer> {

    @Query("SELECT DISTINCT d.addonmenu FROM Menuaddondetail d " +
            "JOIN d.menuaddongroup mg " +
            "JOIN mg.menus m " +
            "WHERE m.restaurant.username = :username")
    List<Addonmenu> findAllByRestaurantUsername(@Param("username") String username);
}