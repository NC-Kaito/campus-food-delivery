package com.it22mjudelivery.springboot_api.v1.RunDATABase;

import com.it22mjudelivery.springboot_api.SpringbootApiApplication;
import com.it22mjudelivery.springboot_api.v1.entities.Faculty;
import com.it22mjudelivery.springboot_api.v1.entities.Major;
import com.it22mjudelivery.springboot_api.v1.repositories.FacultyRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.MajorRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RunFacultyMajor {
    public static void main(String[] args) {
        ApplicationContext context = SpringApplication.run(SpringbootApiApplication.class, args);

        // อย่าลืมสร้าง FacultyRepository และ MajorRepository ไว้ด้วยนะครับ
        FacultyRepository facultyRepository = context.getBean(FacultyRepository.class);
        MajorRepository majorRepository = context.getBean(MajorRepository.class);

        // =========================================================================
        // STEP 1: เตรียมข้อมูลคณะและสาขาทั้งหมด
        // =========================================================================
        Map<String, List<String>> universityData = new LinkedHashMap<>();

        universityData.put("ผลิตกรรมการเกษตร", Arrays.asList("การส่งเสริมและสื่อสารเกษตร", "ปฐพีศาสตร์", "วิทยาการสมุนไพร", "อารักขาพืช", "พืชไร่"));
        universityData.put("วิศวกรรมและอุตสาหกรรมเกษตร", Arrays.asList("เทคโนโลยีหลังการเก็บเกี่ยว", "วิทยาศาสตร์และเทคโนโลยีการอาหาร", "เทคโนโลยียางและพอลิเมอร์", "วิศวกรรมเกษตร", "วิศวกรรมอาหาร"));
        universityData.put("วิทยาศาสตร์", Arrays.asList("วัสดุศาสตร์", "คณิตศาสตร์", "เคมีอุตสาหกรรมและเทคโนโลยีสิ่งทอ", "เทคโนโลยีชีวภาพ", "เทคโนโลยีสารสนเทศ", "ฟิสิกส์ประยุกต์", "เคมี", "วิทยาการคอมพิวเตอร์", "สถิติและการจัดการสารสนเทศ"));
        universityData.put("วิทยาลัยบริหารศาสตร์", Arrays.asList("รัฐศาสตร์"));
        universityData.put("บริหารธุรกิจ", Arrays.asList("นวัตกรรมธุรกิจค้าปลีกสมัยใหม่", "การบริหารการเงินและการลงทุน", "นวัตกรรมการตลาด และการตลาดดิจิทัล", "การจัดการ", "นวัตกรรมธุรกิจดิจิทัล", "บัญชี"));
        universityData.put("พัฒนาการท่องเที่ยว", Arrays.asList("การจัดการธุรกิจท่องเที่ยว", "พัฒนาการท่องเที่ยว"));
        universityData.put("เทคโนโลยีการประมงและทรัพยากรทางน้ำ", Arrays.asList("การประมง", "นวัตกรรมการจัดการธุรกิจประมง"));
        universityData.put("เศรษฐศาสตร์", Arrays.asList("เศรษฐศาสตร์", "เศรษฐศาสตร์เกษตรและสิ่งแวดล้อม", "เศรษฐศาสตร์ระหว่างประเทศ", "เศรษฐศาสตร์สหกรณ์"));
        universityData.put("ศิลปศาสตร์", Arrays.asList("นวัตกรรมสังคม", "นิเทศศาสตร์บูรณาการ", "ภาษาไทยสำหรับชาวต่างประเทศ", "ภาษาอังกฤษ"));
        universityData.put("วิทยาลัยพลังงานทดแทน", Arrays.asList("พลังงานทดแทน", "วิศวกรรมพลังงาน ( วิชาเอกวิศวกรรมพลังงานทดแทน)", "วิศวกรรมการอนุรักษ์พลังงาน", "วิศวกรรมฟาร์มอัจฉริยะและนวัตกรรมเกษตร วิชาเอกวิศวกรรมฟาร์มอัจฉริยะ"));
        universityData.put("สารสนเทศและการสื่อสาร", Arrays.asList("การสื่อสารดิจิทัล"));
        universityData.put("สถาปัตยกรรมศาสตร์และการออกแบบสิ่งแวดล้อม", Arrays.asList("ภูมิสถาปัตยกรรมศาสตรบัณฑิต (ภูมิสถาปัตยกรรม)", "เทคโนโลยีภูมิทัศน์"));
        universityData.put("สัตวศาสตร์และเทคโนโลยี", Arrays.asList("สัตวศาสตร์"));
        universityData.put("พยาบาลศาสตร์", Arrays.asList("หลักสูตรพยาบาลศาสตรบัณฑิต"));
        universityData.put("สัตวแพทยศาสตร์", Arrays.asList("เทคนิคการสัตวแพทย์และการพยาบาลสัตว์"));

        // =========================================================================
        // STEP 2: บันทึกคณะและสาขาลง Database
        // =========================================================================
        List<Major> allMajorsToSave = new ArrayList<>();

        for (Map.Entry<String, List<String>> entry : universityData.entrySet()) {
            // สร้างและบันทึกข้อมูลคณะก่อน
            Faculty faculty = Faculty.builder()
                    .facultyname(entry.getKey())
                    .build();
            faculty = facultyRepository.save(faculty); // เซฟลงฐานข้อมูลเพื่อให้ได้ ID มาผูกกับสาขา

            // สร้างข้อมูลสาขาโดยผูกกับคณะข้างต้น
            for (String majorName : entry.getValue()) {
                Major major = Major.builder()
                        .majorname(majorName)
                        .faculty(faculty) // ผูก Object คณะ
                        .build();
                allMajorsToSave.add(major);
            }
        }

        // บันทึกสาขาทั้งหมดลงฐานข้อมูลพร้อมกัน
        majorRepository.saveAll(allMajorsToSave);

        System.out.println("====== Inserted all Faculties and Majors successfully! ======");
    }
}