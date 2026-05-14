package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Major;

import java.util.List;

public interface MajorService {
    List<Major> getAllMajors();
    List<Major> getMajorsByFaculty(int facultyId);
}
