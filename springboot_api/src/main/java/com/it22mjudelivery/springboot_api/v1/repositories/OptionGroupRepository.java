package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Optiongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface OptionGroupRepository extends JpaRepository<Optiongroup, Integer> {

    // 1. ดึงกลุ่มตัวเลือกทั้งหมดของ Menu
    @Query("SELECT og FROM Optiongroup og WHERE og.menu.menuid = :menuId")
    List<Optiongroup> findByMenuId(@Param("menuId") Integer menuId);

    List<Optiongroup> findByMenu_Menuid(Integer menuid);

    // 2. ดึงกลุ่มตัวเลือกตาม username ของร้านค้า
    @Query("SELECT og FROM Optiongroup og WHERE og.menu.restaurant.username = :username")
    List<Optiongroup> findAllByRestaurantUsername(@Param("username") String username);

    List<Optiongroup> findByMenu_Restaurant_Username(String username);

    // 3. ลบกลุ่มตัวเลือกทั้งหมดที่ผูกกับเมนูนี้
    @Modifying
    @Transactional
    @Query("DELETE FROM Optiongroup og WHERE og.menu = :menu")
    void deleteByMenu(@Param("menu") Menu menu);

    @Modifying
    @Transactional
    void deleteByMenu_Menuid(Integer menuId);

    List<Optiongroup> findByMenu(Menu menu);
}
