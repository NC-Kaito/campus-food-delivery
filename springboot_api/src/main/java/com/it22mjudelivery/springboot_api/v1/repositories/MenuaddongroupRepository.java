package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface MenuaddongroupRepository extends JpaRepository<Menuaddongroup, Integer> {

    // 🎯 จุดที่ 1: ตรวจสอบและเปลี่ยนจาก mg.menu -> mg.menus และ m.id -> m.menuid
    @Query("SELECT DISTINCT mg FROM Menuaddongroup mg " +
            "JOIN mg.menus m " +
            "WHERE m.menuid = :menuId")
    List<Menuaddongroup> findByMenuId(@Param("menuId") Integer menuId);

    // 🎯 จุดที่ 2: ดักทาง Spring ไม่ให้เจนคำสั่งอัตโนมัติ (เปลี่ยนชื่อเมธอดหนีคำว่า findByMenu_Menuid)
    @Query("SELECT DISTINCT mg FROM Menuaddongroup mg " +
            "JOIN mg.menus m " +
            "WHERE m.menuid = :menuid")
    List<Menuaddongroup> findGroupsByMenuId(@Param("menuid") Integer menuid);

    // แก้ — ดึงตรงจาก restaurant ที่ผูกใน Menuaddongroup โดยตรง
    @Query("SELECT mg FROM Menuaddongroup mg " +
            "WHERE mg.username.username = :username")
    List<Menuaddongroup> findAllByRestaurantUsername(
            @Param("username") String username);

    // 🎯 จุดที่ 3: คำสั่งลบความสัมพันธ์ในรูปแบบ @ManyToMany
    @Modifying
    @Transactional
    @Query("DELETE FROM Menuaddongroup mg WHERE :menu MEMBER OF mg.menus")
    void deleteByMenu(@Param("menu") Menu menu);


    // เพิ่มโค้ด 2 ส่วนนี้ต่อท้ายใน MenuaddongroupRepository.java
    @Query("SELECT COUNT(m) FROM Menuaddongroup mg JOIN mg.menus m WHERE mg.addongroupid = :groupId")
    int countMenusByGroupId(@Param("groupId") Integer groupId);

    // 🎯 แก้ไขชื่อคอลัมน์จาก addongroupid เป็น addongroup_id ครับ
    @Modifying
    @Transactional
    @Query(value = "DELETE FROM menu_addongroups WHERE addongroup_id = :groupId", nativeQuery = true)
    void removeAllMenuLinks(@Param("groupId") Integer groupId);
}