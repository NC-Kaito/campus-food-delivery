package com.it22mjudelivery.springboot_api.v1.rundata;

import com.it22mjudelivery.springboot_api.v1.entities.Faculty;
import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.repositories.FacultyRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MajorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

@Component
@RequiredArgsConstructor
public class AddFacultyAndMajor implements CommandLineRunner {

    private final FacultyRepository facultyRepository;
    private final MajorRepository majorRepository;

    @Override
    public void run(String... args) throws Exception {
        // 1. เพิ่มคณะ (ถ้ายังไม่มี)
        if (facultyRepository.count() == 0) {
            List<Faculty> faculties = Arrays.asList(
                    Faculty.builder().facultyname("คณะวิทยาศาสตร์").build(),
                    Faculty.builder().facultyname("คณะบริหารธุรกิจ").build(),
                    Faculty.builder().facultyname("คณะวิศวกรรมและอุตสาหกรรมเกษตร").build(),
                    Faculty.builder().facultyname("คณะผลิตกรรมการเกษตร").build()
            );
            facultyRepository.saveAll(faculties);
            System.out.println("✅ เพิ่มข้อมูลคณะเรียบร้อยแล้ว!");
        }

        // 2. เพิ่มสาขา (ถ้ายังไม่มี)
        if (majorRepository.count() == 0) {
            List<Faculty> allFaculties = facultyRepository.findAll();

            // หาคณะเพื่อนำมาผูกกับสาขา
            Faculty science = allFaculties.stream()
                    .filter(f -> f.getFacultyname().equals("คณะวิทยาศาสตร์"))
                    .findFirst().orElse(null);

            Faculty business = allFaculties.stream()
                    .filter(f -> f.getFacultyname().equals("คณะบริหารธุรกิจ"))
                    .findFirst().orElse(null);

            if (science != null && business != null) {
                List<Major> majors = Arrays.asList(
                        // สาขาในคณะวิทยาศาสตร์
                        Major.builder().majorname("วิทยาการคอมพิวเตอร์").faculty(science).build(),
                        Major.builder().majorname("เทคโนโลยีสารสนเทศ").faculty(science).build(),
                        Major.builder().majorname("สถิติ").faculty(science).build(),

                        // สาขาในคณะบริหารธุรกิจ
                        Major.builder().majorname("การตลาด").faculty(business).build(),
                        Major.builder().majorname("บัญชี").faculty(business).build(),
                        Major.builder().majorname("ระบบสารสนเทศทางธุรกิจ").faculty(business).build()
                );

                majorRepository.saveAll(majors);
                System.out.println("✅ เพิ่มข้อมูลสาขาเรียบร้อยแล้ว!");
            }
        }
    }
}