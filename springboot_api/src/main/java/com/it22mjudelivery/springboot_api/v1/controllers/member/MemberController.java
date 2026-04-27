package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;

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

    @PostMapping("/updateProfileMember")
    public ResponseEntity<?> updateProfileMember(@RequestBody MemberDto memberDto){
        try{
            boolean isResult = memberService.doUpdateProfileMember(memberDto.getUsername(), memberDto.getPhone(), memberDto.getProfileimg());

            if (isResult){
                return ResponseEntity.ok("แก้ไขโปรไฟล์สำเร็จ");
            }
            return ResponseEntity.badRequest().body("แก้ไขไม่สำเร็จ ข้อมูลไม่ถูกต้อง");
        }catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body("เกิดข้อผิดพลาดที่ระบบ");
        }
    }

    @PostMapping("/uploadProfileImage")
    public ResponseEntity<?> uploadProfileImage(@RequestParam("image") MultipartFile file) {
        try {
            // สร้างชื่อไฟล์ไม่ซ้ำกัน
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();

            // สร้างโฟลเดอร์ uploads ถ้ายังไม่มี
            Path uploadDir = Paths.get("uploads");
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            // บันทึกไฟล์
            Path savePath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), savePath);

            // return URL กลับไป
            String imageUrl = "http://10.226.43.211:8081/uploads/" + fileName;
            return ResponseEntity.ok(Map.of("url", imageUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }
}
