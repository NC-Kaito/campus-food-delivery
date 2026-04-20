package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.repositories.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MemberServiceImpl implements MemberService{
    private final MemberRepository memberRepository;

    public Member doLoginMember(String username, String password) {
             Member member = memberRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));

             if(!member.getPassword().equals(password)) {
                throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
             }
             return member;
    }
}
