package com.it22mjudelivery.springboot_api.v1.dtos;

import com.it22mjudelivery.springboot_api.v1.entities.Order;
import jakarta.persistence.Column;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewDto {
    // 🎯 เปลี่ยนจาก int เป็น Integer ตรงนี้ครับ เพื่อให้รับค่า null ตอนสร้างรีวิวใหม่ได้
    private Integer reviewid;

    private LocalDateTime reviewdate;
    private int restaurantrating;
    private int riderrating;
    private String commentrestaurant;
    private String cleanliness;
    private String taste_rating;
    private String delivery_speed;
    private String food_condition;
    private String commentrider;
    private int orderid;
}