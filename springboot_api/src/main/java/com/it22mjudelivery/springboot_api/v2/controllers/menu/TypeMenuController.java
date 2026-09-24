package com.it22mjudelivery.springboot_api.v2.controllers.menu;

import com.it22mjudelivery.springboot_api.v2.entities.TypeMenu;
import com.it22mjudelivery.springboot_api.v2.repositories.TypeMenuRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

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
