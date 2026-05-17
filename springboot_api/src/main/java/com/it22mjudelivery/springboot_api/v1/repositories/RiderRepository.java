package com.it22mjudelivery.springboot_api.v1.repositories;

import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RiderRepository extends JpaRepository<Rider,String> {
    boolean existsByStudentid(String studentId);

    boolean existsByEmail(String email);

    Optional<Rider> findByStudentid(String studentId);

    List<Rider> findByVerificationStatus(String status);
    long countByVerificationStatus(String verificationstatus);
}
