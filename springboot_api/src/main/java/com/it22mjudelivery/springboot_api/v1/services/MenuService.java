package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Menu;

import java.util.List;

public interface MenuService {
    List<Menu> getMenusByRestaurant(String username);
}
