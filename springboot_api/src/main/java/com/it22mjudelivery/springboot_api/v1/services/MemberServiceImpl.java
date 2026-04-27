package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
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
}
