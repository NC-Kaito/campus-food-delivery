package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.repositories.MajorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MajorServiceImpl implements MajorService {
    private final MajorRepository majorRepository;

    @Override
    public List<Major> getMajorsByFaculty(int facultyId) {
        // มี Logic เล็กๆ คือการค้นหาตาม ID คณะ
        return majorRepository.findByFaculty_Facultyid(facultyId);
    }

    @Override
    public List<Major> getAllMajors() {
        return majorRepository.findAll();
    }
}