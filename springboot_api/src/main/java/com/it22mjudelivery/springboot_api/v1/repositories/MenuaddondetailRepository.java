package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Option;
import com.it22mjudelivery.springboot_api.v1.entities.Optiongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuaddondetailRepository extends JpaRepository<Option, Integer> {

    @Query("SELECT md FROM Menuaddondetail md " +
            "JOIN FETCH md.menuaddongroup mg " +
            "JOIN FETCH md.addonmenu am " +
            "JOIN mg.menus m " +          // ← เปลี่ยนจาก mg.menu เป็น JOIN mg.menus
            "WHERE m.menuid = :menuId")   // ← เปลี่ยนจาก mg.menu.id เป็น m.menuid
    List<Option> findAddonsByMenuId(@Param("menuId") Long menuId);

    List<Option> findByMenuaddongroup(Optiongroup menuaddongroup);

    void deleteByMenuaddongroup(Optiongroup menuaddongroup);


}
