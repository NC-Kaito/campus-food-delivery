package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.ReviewDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Optiongroup;
import com.it22mjudelivery.springboot_api.v1.entities.Review;
import com.it22mjudelivery.springboot_api.v1.repositories.OptionGroupRepository;
import com.it22mjudelivery.springboot_api.v1.services.CloudinaryService;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/member")
public class MemberController {

    private final MemberService memberService;
    private final CloudinaryService cloudinaryService;

    // 🎯 แก้ไข: ใช้ OptionGroupRepository และใส่ final เพื่อให้ DI ทำงาน
    private final OptionGroupRepository optionGroupRepository;

    @PostMapping("/loginMember")
    public ResponseEntity doLoginMember(@RequestBody MemberDto memberDto){
        try {
            Member member = memberService.doLoginMember(memberDto.getUsername(), memberDto.getPassword());
            return ResponseEntity.ok(member);
        } catch (RuntimeException e){
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        } catch (Exception e){
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/registerMember")
    public ResponseEntity doRegisterMember(@RequestBody MemberDto memberDto) {
        try {
            boolean isResult = memberService.doRegisterMember(memberDto);
            if (isResult) {
                return ResponseEntity.ok("สมัครสมาชิกสำเร็จ");
            }
            return ResponseEntity.badRequest().body("สมัครสมาชิกไม่สำเร็จ");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @GetMapping("/getMember")
    public ResponseEntity getMemberByUsername(@RequestParam("username") String username) {
        Member member = memberService.getMemberByUsername(username);
        if (member != null){
            return ResponseEntity.ok(member);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("ไม่พบผู้ใช้งานนี้");
        }
    }

    @PostMapping("/updateProfileMember")
    public ResponseEntity updateProfileMember(@RequestBody MemberDto memberDto){
        try {
            boolean isResult = memberService.doUpdateProfileMember(
                    memberDto.getUsername(),
                    memberDto.getFirstname(),
                    memberDto.getLastname(),
                    memberDto.getPhone(),
                    memberDto.getProfileimg()
            );

            if (isResult){
                return ResponseEntity.ok("แก้ไขโปรไฟล์สำเร็จ");
            }
            return ResponseEntity.badRequest().body("แก้ไขไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/uploadProfileImage")
    public ResponseEntity uploadProfileImage(@RequestParam("image") MultipartFile file) {
        try {
            String folderName = "maejo_delivery/members/profile";
            String publicUrl = cloudinaryService.uploadImage(file, folderName);
            return ResponseEntity.ok(Map.of("url", publicUrl));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

    // 🎯 ตัด /v1 ออก เพราะคลาสมี @RequestMapping("/v1/member") อยู่แล้ว (URL จะกลายเป็น /v1/member/menu-addons/{menuId})
    @GetMapping("/menu-addons/{menuId}")
    public ResponseEntity getMenuAddons(@PathVariable Integer menuId) {
        List addonGroups = optionGroupRepository.findByMenuId(menuId);

        if (addonGroups == null || addonGroups.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }

        return ResponseEntity.ok(addonGroups);
    }

    @PostMapping("/addReview")
    public ResponseEntity addReview(@RequestBody ReviewDto reviewDto) {
        try {
            Review review = memberService.addReview(reviewDto);
            return ResponseEntity.ok(review);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @GetMapping("/getReview/{orderId}")
    public ResponseEntity getReviewByOrderId(@PathVariable int orderId) {
        try {
            Review review = memberService.getReviewByOrderId(orderId);
            return ResponseEntity.ok(review);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/updateLocationMember")
    public ResponseEntity updateLocationMember(@RequestBody MemberDto memberDto){
        try {
            boolean isResult = memberService.updateLocationMember(
                    memberDto.getUsername(),
                    memberDto.getLatitude(),
                    memberDto.getLongitude(),
                    memberDto.getDefaultLocation()
            );

            if (isResult){
                return ResponseEntity.ok("แก้ไขจุดส่งสำเร็จ");
            }
            return ResponseEntity.badRequest().body("แก้ไขไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }
}