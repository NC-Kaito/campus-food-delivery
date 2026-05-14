package com.it22mjudelivery.springboot_api.v1.controllers.rider;

import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.services.MajorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/v1/majors")
@RequiredArgsConstructor
public class MajorController {
    private final MajorService majorService; // ✅ เชื่อมผ่าน Service

    @GetMapping("/majorsByFaculty/{facultyId}")
    public ResponseEntity<List<Major>> getByFaculty(@PathVariable int facultyId) {
        return ResponseEntity.ok(majorService.getMajorsByFaculty(facultyId));
    }
}