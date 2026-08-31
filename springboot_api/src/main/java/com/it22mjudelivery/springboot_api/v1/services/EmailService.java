package com.it22mjudelivery.springboot_api.v1.services;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async; // 🎯 1. นำเข้า Async
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    // รองรับการส่งแบบ HTML เพื่อให้ใส่สีและขนาดตัวอักษรได้
    @Async // 🎯 2. เติม @Async ตรงนี้ เพื่อให้ระบบส่งอีเมลทำงานอยู่เบื้องหลัง
    public void sendEmailHtml(String to, String subject, String htmlBody) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlBody, true); // true หมายถึงให้มองข้อความ เป็น HTML
            mailSender.send(message);
        } catch (MessagingException e) {
            e.printStackTrace();
        }
    }
}