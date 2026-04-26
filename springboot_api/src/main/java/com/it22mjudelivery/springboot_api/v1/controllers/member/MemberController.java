package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/member")
public class MemberController {
    private final MemberService memberService;

    @PostMapping("/loginMember")
    public ResponseEntity<?> doLoginMember(@RequestBody MemberDto memberDio){
        try {
            Member member = memberService.doLoginMember(memberDio.getUsername(), memberDio.getPassword());
            return ResponseEntity.ok(member);
        }catch (RuntimeException e){
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(e.getMessage());
        }catch (Exception e){
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/registerMember")
    public ResponseEntity<?> doRegisterMember(@RequestBody MemberDto memberDto) {
        try {
            boolean isResult = memberService.doRegisterMember(memberDto);
            if (isResult) {
                return ResponseEntity.ok("สมัครสมาชิกสำเร็จ");
            }
            return ResponseEntity.badRequest().body("สมัครสมาชิกไม่สำเร็จ");
        } catch (RuntimeException e) {
            // จับข้อความที่เรา throw เช่น "ชื่อผู้ใช้งานนี้ถูกใช้ไปแล้ว"
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            // กรณีเกิด Error อื่นๆ ที่ไม่ได้คาดคิด
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @GetMapping("/getMember")
    public ResponseEntity<?> getMemberByUsername(@RequestBody MemberDto memberDto) {
        Member member = memberService.getMemberByUsername(memberDto.getUsername());
        if(member != null){
            return ResponseEntity.ok(member);
        }else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("ไม่พบผู้ใช้งานนี้");
        }
    }
}
