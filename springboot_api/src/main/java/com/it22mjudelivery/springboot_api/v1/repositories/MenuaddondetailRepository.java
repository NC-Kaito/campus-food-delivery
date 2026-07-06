package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Menuaddondetail;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.awt.*;
import java.util.List;

@Repository
public interface MenuaddondetailRepository extends JpaRepository<Menuaddondetail, Integer> {

    @Query("SELECT md FROM Menuaddondetail md " +
            "JOIN FETCH md.menuaddongroup mg " +
            "JOIN FETCH md.addonmenu am " +
            "JOIN mg.menus m " +          // ← เปลี่ยนจาก mg.menu เป็น JOIN mg.menus
            "WHERE m.menuid = :menuId")   // ← เปลี่ยนจาก mg.menu.id เป็น m.menuid
    List<Menuaddondetail> findAddonsByMenuId(@Param("menuId") Long menuId);

    List<Menuaddondetail> findByMenuaddongroup(Menuaddongroup menuaddongroup);
}
