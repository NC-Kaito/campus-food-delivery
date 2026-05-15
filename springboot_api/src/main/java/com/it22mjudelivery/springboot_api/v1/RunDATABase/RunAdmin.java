package com.it22mjudelivery.springboot_api.v1.RunDATABase;

import com.it22mjudelivery.springboot_api.SpringbootApiApplication;
import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.repositories.AdminRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;

public class RunAdmin {
    public static void main(String[] args) {
        ApplicationContext context = SpringApplication.run(SpringbootApiApplication.class, args);
        AdminRepository adminRepository = context.getBean(AdminRepository.class);

        //-----insert Word----------------------------------------------------------------------------------
        Admin admin = new Admin("naree", "12345678", "นารีย์", "แซ่ย่าง");
        adminRepository.save(admin);

        System.out.println("Inserted sample words successfully!");

        SpringApplication.exit(context);
    }
}
