package com.it22mjudelivery.springboot_api.v1.controllers.menu;

import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeMenuRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.services.MenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/typemenu")
public class TypeMenuController {
    @Autowired
    private TypeMenuRepository typeMenuRepository;
    @GetMapping
    public ResponseEntity<List<TypeMenu>> getAllTypes() {
        return ResponseEntity.ok(typeMenuRepository.findAll());
    }

}
