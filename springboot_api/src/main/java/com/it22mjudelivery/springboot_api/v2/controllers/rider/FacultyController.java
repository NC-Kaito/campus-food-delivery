package com.it22mjudelivery.springboot_api.v2.controllers.rider;

import com.it22mjudelivery.springboot_api.v2.entities.Faculty;
import com.it22mjudelivery.springboot_api.v2.services.FacultyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1/faculty")
@RequiredArgsConstructor
public class FacultyController {
    private final FacultyService facultyService;
     @GetMapping("/getFacultys")
    public ResponseEntity<List<Faculty>> getByFaculty() {
        return ResponseEntity.ok(facultyService.getAllFaculty());
    }
}
