package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Menuaddondetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuaddondetailRepository extends JpaRepository<Menuaddondetail, Integer> {

    // ดึงรายละเอียดเมนูเสริมทั้งหมด โดยเจาะจงที่รหัสเมนูหลัก (Menu ID)
    // สั่ง JOIN FETCH เพื่อดึงข้อมูลกลุ่ม (Group) และชื่อเมนูเสริม (Addonmenu) ติดสอยมาด้วยทันที
    @Query("SELECT md FROM Menuaddondetail md " +
            "JOIN FETCH md.menuaddongroup mg " +
            "JOIN FETCH md.addonmenu am " +
            "WHERE mg.menu.id = :menuId")
    List<Menuaddondetail> findAddonsByMenuId(@Param("menuId") Long menuId);
}
