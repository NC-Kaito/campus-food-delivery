package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Addonmenu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AddonmenuRepository extends JpaRepository<Addonmenu, Integer> {

    // 🌟 คิวรีดึงรายชื่อแอดออนทั้งหมดที่เป็นของเมนูอาหารในร้านค้านี้ (ป้องกันข้อมูลร้านอื่นปนเข้ามา)
    @Query("SELECT DISTINCT d.addonmenu " +
            "FROM Menuaddondetail d " +
            "WHERE d.menuaddongroup.menu.restaurant.username = :username")
    List<Addonmenu> findAllByRestaurantUsername(@Param("username") String username);
}