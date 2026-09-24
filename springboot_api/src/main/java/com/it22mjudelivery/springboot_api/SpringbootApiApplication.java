package com.it22mjudelivery.springboot_api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;


@SpringBootApplication(scanBasePackages = "com.it22mjudelivery.springboot_api.v1")
@EntityScan(basePackages = "com.it22mjudelivery.springboot_api.v1")
@EnableJpaRepositories(basePackages = "com.it22mjudelivery.springboot_api.v1")
@EnableAsync
@EnableScheduling
public class SpringbootApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootApiApplication.class, args);
    }

}
