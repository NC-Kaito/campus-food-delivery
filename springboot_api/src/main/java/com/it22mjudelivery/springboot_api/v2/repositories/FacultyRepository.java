package com.it22mjudelivery.springboot_api.v2.repositories;

import com.it22mjudelivery.springboot_api.v2.entities.Faculty;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FacultyRepository extends JpaRepository<Faculty, Integer> {

}
