package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MenuDto;
import com.it22mjudelivery.springboot_api.v1.entities.Menu;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;

import java.util.List;
import java.util.Map;
import java.util.Set;

public interface MenuService {
    List<Menu> getMenusByRestaurant(String username);
    List<Menu> getMenusByRestaurantAndTypeMenu(String username, Integer typeMenuId);
    boolean updateMenuStatus(int menuId, boolean status);
    boolean saveMenuWithAddons(Map<String, Object> requestData);
    boolean saveMenu(MenuDto requestData);
    //boolean updateMenu(Map<String, Object> requestData);
    boolean updateMenuByRestaurant(Map<String, Object> requestData);
    boolean deleteMenu(int menuId);

    boolean updateMenuMapping(Integer menuId, List<Integer> addonGroupIds);

//    Set<Menuaddongroup> getAddonsByTypeMenuId(int id);


}
