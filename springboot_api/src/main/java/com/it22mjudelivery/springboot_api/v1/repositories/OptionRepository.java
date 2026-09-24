package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Option;
import com.it22mjudelivery.springboot_api.v1.entities.Optiongroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface OptionRepository extends JpaRepository<Option, Integer> {

    // 1. ดึงตัวเลือกทั้งหมดภายใต้ MenuId (option -> optiongroup -> menu)
    @Query("SELECT o FROM Option o WHERE o.optiongroup.menu.menuid = :menuId")
    List findOptionsByMenuId(@Param("menuId") Integer menuId);

    // 2. ค้นหา Option ตามกลุ่ม Optiongroup
    List findByOptiongroup(Optiongroup optiongroup);

    List findByOptiongroup_Optiongroupid(Integer optiongroupId);

    // 3. ลบ Option ทั้งหมดในกลุ่ม
    @Modifying
    @Transactional
    void deleteByOptiongroup(Optiongroup optiongroup);

    @Modifying
    @Transactional
    void deleteByOptiongroup_Optiongroupid(Integer optiongroupId);
}