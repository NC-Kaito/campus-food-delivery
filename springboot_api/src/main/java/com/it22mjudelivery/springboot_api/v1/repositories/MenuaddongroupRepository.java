package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuaddongroupRepository extends JpaRepository<Menuaddongroup, Integer> {
    // ดึงกลุ่มเมนูเสริม พร้อมโหลดรายละเอียดและชื่อเมนูเสริมพ่วงมาด้วยใน Query เดียวกัน
    @Query("SELECT DISTINCT mg FROM Menuaddongroup mg " +
            "LEFT JOIN FETCH mg.menu m " +
            "WHERE m.id = :menuId")
    List<Menuaddongroup> findByMenuId(@Param("menuId") Long menuId);

    List<Menuaddongroup> findByMenu_Menuid(Long menuid);
}
