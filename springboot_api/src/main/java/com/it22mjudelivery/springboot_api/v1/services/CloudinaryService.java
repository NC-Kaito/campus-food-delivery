package com.it22mjudelivery.springboot_api.v1.services;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@Service
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public CloudinaryService(Cloudinary cloudinary) {
        this.cloudinary = cloudinary;
    }

    // 🎯 เพิ่มพารามิเตอร์ folderName เข้ามา
    public String uploadImage(MultipartFile file, String folderName) {
        try {
            // 🎯 ตั้งค่าพารามิเตอร์ให้ Cloudinary รู้ว่าจะเอาไปเก็บไว้ที่โฟลเดอร์ไหน
            Map<String, Object> uploadOptions = ObjectUtils.asMap(
                    "folder", folderName
            );

            // โยนไฟล์ขึ้น Cloudinary พร้อมแนบออปชันโฟลเดอร์ไปด้วย
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), uploadOptions);

            return uploadResult.get("url").toString();

        } catch (IOException e) {
            throw new RuntimeException("เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: " + e.getMessage());
        }
    }
}