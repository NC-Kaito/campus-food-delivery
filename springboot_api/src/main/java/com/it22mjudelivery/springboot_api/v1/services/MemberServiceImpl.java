package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.ReviewDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Order;
import com.it22mjudelivery.springboot_api.v1.entities.Review;
import com.it22mjudelivery.springboot_api.v1.repositories.MemberRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.OrderRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class MemberServiceImpl implements MemberService{
    private final MemberRepository memberRepository;
    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;

    public Member doLoginMember(String username, String password) {
             Member member = memberRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง"));

             if(!member.getPassword().equals(password)) {
                throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
             }
             return member;
    }

    public boolean doRegisterMember(MemberDto memberDto){
        if (memberRepository.existsByUsername(memberDto.getUsername())) {
            throw new RuntimeException("ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว");
        }
        if (memberRepository.existsByEmail(memberDto.getEmail())) {
            throw new RuntimeException("อีเมลนี้ถูกใช้งานไปแล้ว");
        }
        Member toSaveMember = Member.builder()
                .username(memberDto.getUsername())
                .password(memberDto.getPassword())
                .firstname(memberDto.getFirstname())
                .lastname(memberDto.getLastname())
                .email(memberDto.getEmail())
                .phone(memberDto.getPhone())
                .build();

        memberRepository.save(toSaveMember);
        return true;
    }

    public Member getMemberByUsername(String username){
        Member member = memberRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));
        return member;
    }

    public boolean doUpdateProfileMember(String username, String phone, String profileImg){
        Member member = memberRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));

        member.setProfileimg(profileImg);
        member.setPhone(phone);
        memberRepository.save(member);
        return true;
    }

    @Override
    public Review addReview(ReviewDto reviewDto) {

        if (reviewDto.getRestaurantrating() < 1 || reviewDto.getRiderrating() < 1) {
            throw new RuntimeException("กรุณาให้คะแนนอย่างน้อย 1 ดาวทั้งร้านค้าและไรเดอร์");
        }

        if (reviewRepository.existsByOrder_Orderid(reviewDto.getOrderid())) {
            throw new RuntimeException("ออเดอร์นี้ถูกรีวิวไปแล้ว");
        }
        Order order = orderRepository.findById(reviewDto.getOrderid())
                .orElseThrow(() -> new RuntimeException("ไม่พบออเดอร์นี้"));

        Review review = Review.builder()
                .reviewdate(LocalDateTime.now())
                .restaurantrating(reviewDto.getRestaurantrating())
                .riderrating(reviewDto.getRiderrating())
                .commentrestaurant(reviewDto.getCommentrestaurant())
                .cleanliness(reviewDto.getCleanliness())
                .taste_rating(reviewDto.getTaste_rating())
                .delivery_speed(reviewDto.getDelivery_speed())
                .food_condition(reviewDto.getFood_condition())
                .commentrider(reviewDto.getCommentrider())
                .order(order)
                .build();

        return reviewRepository.save(review);
    }

    @Override
    public Review getReviewByOrderId(int orderId) {
        return reviewRepository.findByOrder_Orderid(orderId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลรีวิวของออเดอร์นี้"));
    }

    }
