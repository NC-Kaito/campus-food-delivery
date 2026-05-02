package com.it22mjudelivery.springboot_api.v1.controllers.restaurant;

import com.it22mjudelivery.springboot_api.v1.entities.TypeRestaurant;
import com.it22mjudelivery.springboot_api.v1.repositories.TypeRestaurantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/typerestaurant")
public class TypeRestaurantController {
    @Autowired
    private TypeRestaurantRepository typeRestaurantRepository;
    @GetMapping
    public ResponseEntity<List<TypeRestaurant>> getAllTypes() {
        return ResponseEntity.ok(typeRestaurantRepository.findAll());
    }
}
