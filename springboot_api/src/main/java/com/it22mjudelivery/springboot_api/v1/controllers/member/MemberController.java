package com.it22mjudelivery.springboot_api.v1.controllers.member;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Menuaddongroup;
import com.it22mjudelivery.springboot_api.v1.repositories.MenuaddongroupRepository;
import com.it22mjudelivery.springboot_api.v1.services.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/v1/member")
public class MemberController {
    private final MemberService memberService;

    private MenuaddongroupRepository menuaddongroupRepo;

    @PostMapping("/loginMember")
    public ResponseEntity<?> doLoginMember(@RequestBody MemberDto memberDto){
        try {
            Member member = memberService.doLoginMember(memberDto.getUsername(), memberDto.getPassword());
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
    public ResponseEntity<?> getMemberByUsername(@RequestParam("username") String username) {
        Member member = memberService.getMemberByUsername(username);
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
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();

            // 🎯 จุดที่ 1: ตรวจเช็คให้มั่นใจว่าพิกัดโฟลเดอร์เก็บไฟล์จริงเอาไว้ที่ไหน
            // แนะนำให้ยิงตรงเข้าโฟลเดอร์ member/ เพื่อความง่ายและสั้นในการจัดพาร์ทครับ
            Path uploadDir = Paths.get("uploads", "member", "profile");
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }

            // บันทึกไฟล์ลงเซิร์ฟเวอร์จริง
            Path savePath = uploadDir.resolve(fileName);
            Files.copy(file.getInputStream(), savePath);

            String imageUrl = "uploads/member/profile/" + fileName;

            return ResponseEntity.ok(Map.of("url", imageUrl));

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("อัปโหลดไม่สำเร็จ: " + e.getMessage());
        }
    }

    @GetMapping("/v1/menu-addons/{menuId}")
    public ResponseEntity<?> getMenuAddons(@PathVariable Long menuId) {

        List<Menuaddongroup> addonGroups = menuaddongroupRepo.findByMenuId(menuId);

        if (addonGroups.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList()); // ถ้าไม่มีส่งกล่องเปล่าไปให้ Flutter เช็ค
        }

        return ResponseEntity.ok(addonGroups);
    }
}
