package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Faculty;
import com.it22mjudelivery.springboot_api.v1.repositories.FacultyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FacultyServiceImpl implements FacultyService{
    private final FacultyRepository facultyRepository;

    public List<Faculty> getAllFaculty(){
        return facultyRepository.findAll();
    }
}
