package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.entities.Major;

import java.util.List;

public interface MajorService {
    List<Major> getAllMajors();
    List<Major> getMajorsByFaculty(int facultyId);
}
