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
}
