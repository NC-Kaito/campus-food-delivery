package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Menu;

import java.util.List;
import java.util.Map;

public interface MenuService {
    List<Menu> getMenusByRestaurant(String username);
    List<Menu> getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId);
    boolean updateMenuStatus(int menuId, boolean status);
    boolean saveMenuWithAddons(Map<String, Object> requestData);



}
