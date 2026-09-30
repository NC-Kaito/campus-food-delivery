package com.it22mjudelivery.springboot_api.v1.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;

import java.util.List;
import java.util.Optional;

@Repository
public interface MenuRepository extends JpaRepository<Menu, Integer> {
    List<Menu> findByRestaurant_username(String username);

    // สำหรับ filter ตาม typeMenu (ถ้าต้องการทำ server-side filter ในอนาคต)
    List<Menu> findByRestaurant_usernameAndTypemenu_typemenuId(String username, Integer typeMenuId);

    Optional<Menu>
    findFirstByRestaurant_UsernameAndTypemenu_TypemenuIdOrderByMenuidAsc(
            String restaurantUsername,
            Integer typeMenuId
    );

    Optional<Menu> findFirstByRestaurant_UsernameAndTypemenu_TypemenuIdAndCurryPriceTemplateTrue(
            String restaurantUsername,
            Integer typeMenuId
    );

    List<Menu> findByRestaurant_usernameAndCurryPriceTemplateFalse(
            String username
    );

    List<Menu> findByRestaurant_usernameAndTypemenu_typemenuIdAndCurryPriceTemplateFalse(
            String username,
            Integer typeMenuId
    );
}
