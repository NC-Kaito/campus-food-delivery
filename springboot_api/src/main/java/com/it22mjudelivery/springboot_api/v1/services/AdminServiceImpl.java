package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Admin;
import com.it22mjudelivery.springboot_api.v1.entities.Restaurant;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;
import com.it22mjudelivery.springboot_api.v1.repositories.AdminRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RestaurantRepository;
import com.it22mjudelivery.springboot_api.v1.repositories.RiderRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminServiceImpl implements AdminService {
    private final AdminRepository adminRepository;
    private final RestaurantRepository restaurantRepository;
    private final RiderRepository riderRepository;
    private final EmailService emailService;

    public Admin doLoginAdmin(String username, String password) {
        Admin admin = adminRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน"));

        if (!admin.getPassword().equals(password)) {
            throw new RuntimeException("ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง");
        }
        return admin;
    }

    @Override
    public List<Restaurant> getList_register_rest() {
        return restaurantRepository.findByVerificationstatus("wait");
    }

    @Override
    public Restaurant getRestaurantById(String id) {
        return restaurantRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลร้านอาหาร ID: " + id));
    }

    // 💖 ส่วนการอนุมัติร้านค้า
    @Override
    public void approveRestaurant(String username) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));

        restaurant.setVerificationstatus("true");
        restaurant.setNotapprovedetail(null);
        restaurantRepository.save(restaurant);

        if (restaurant.getEmail() != null && !restaurant.getEmail().isEmpty()) {
            String subject = "แจ้งผลการพิจารณาการสมัครใช้งานระบบร้านค้า - " + restaurant.getRestaurantname();
            String body =
                    "<h1 style='color: #28a745; font-size: 32px; font-weight: bold; text-align: center;'>【 อนุมัติ 】</h1>" +
                            "<p>เรียน คุณ " + restaurant.getOwnerfirstname() + " " + restaurant.getOwnerlastname() + ",</p>" +
                            "<p>ทางเราขอขอบพระคุณเป็นอย่างยิ่งที่ท่านได้ให้ความสนใจและสมัครเข้าร่วมเป็นร้านค้าในระบบของเรา ทางทีมงานได้ทำการตรวจสอบข้อมูลการสมัครของร้านค้า " + restaurant.getRestaurantname() + " เป็นที่เรียบร้อยแล้ว และมีความยินดีอย่างยิ่งที่จะแจ้งให้ทราบว่า บัญชีร้านค้าของท่านได้รับการอนุมัติให้เข้าใช้งานระบบเป็นที่เรียบร้อยแล้ว</p>" +
                            "<p>ท่านสามารถเข้าสู่ระบบเพื่อเริ่มใช้งานร้านค้าได้แล้ว ณ ตอนนี้</p>" +
                            "<p>ขอแสดงความนับถือ,<br>ทีมงาน ระบบจัดส่งอาหารร้านค้าภายในมหาวิทยาลัยแม่โจ้</p>";

            emailService.sendEmailHtml(restaurant.getEmail(), subject, body);
        }
    }

    @Override
    public void rejectRestaurant(String username, String reason) {
        Restaurant restaurant = restaurantRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งานร้านค้า: " + username));

        // 1. ส่งอีเมลแจ้งผลก่อน
        if (restaurant.getEmail() != null && !restaurant.getEmail().isEmpty()) {
            String subject = "แจ้งผลการพิจารณาการสมัครใช้งานระบบร้านค้า -  " + restaurant.getRestaurantname();
            String body =
                    "<h1 style='color: #dc3545; font-size: 32px; font-weight: bold; text-align: center;'>【 ไม่อนุมัติ 】</h1>" +
                            "<p>เรียน คุณ " + restaurant.getOwnerfirstname() + " " + restaurant.getOwnerlastname() + ",</p>" +
                            "<p>ทางเราขอขอบพระคุณเป็นอย่างยิ่งที่ท่านได้ให้ความสนใจและสมัครเข้าร่วมเป็นร้านค้าในระบบของเรา ทางทีมงานได้ทำการตรวจสอบข้อมูลการสมัครของ " + restaurant.getRestaurantname() + " แล้ว ทางเราขออภัยที่ต้องแจ้งให้ทราบว่าบัญชีร้านค้าของท่านยังไม่ผ่านการอนุมัติในขณะนี้</p>" +
                            "<div style='background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; border-left: 5px solid #dc3545; padding: 12px 16px; border-radius: 4px; margin: 15px 0;'>" +
                            "<strong>เหตุผล:</strong> " + reason +
                            "</div>" +
                            "<p>ท่านสามารถทำการสมัครสมาชิกใหม่อีกครั้งได้</p>" +
                            "<p>ขอแสดงความนับถือ,<br>ทีมงาน ระบบจัดส่งอาหารร้านค้าภายในมหาวิทยาลัย</p>";

            emailService.sendEmailHtml(restaurant.getEmail(), subject, body);
        }

        // 2. ลบข้อมูลออกจากฐานข้อมูล
        restaurantRepository.delete(restaurant);
    }
    //--------Rider-------------------------------------------------------------------------------------
    @Override
    public List<Rider> getList_register_rider() {
        return riderRepository.findByVerificationStatus("wait");
    }

    @Override
    public Rider getRiderById(String studentId) {
        return riderRepository.findById(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบข้อมูลผู้จัดส่ง ID: " + studentId));
    }

    // 💖 ส่วนการอนุมัติไรเดอร์
    @Override
    public void approveRider(String studentId) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน: " + studentId));

        rider.setVerificationStatus("true");
        rider.setNotApproveDetail(null);
        riderRepository.save(rider);

        if (rider.getEmail() != null && !rider.getEmail().isEmpty()) {
            String subject = "แจ้งผลการพิจารณาการสมัครผู้จัดส่งอาหาร - " + rider.getFirstName() + " " + rider.getLastName();
            String body =
                    "<h1 style='color: #28a745; font-size: 32px; font-weight: bold; text-align: center;'>【 อนุมัติ 】</h1>" +
                            "<p>เรียน คุณ " + rider.getFirstName() + " " + rider.getLastName() + ",</p>" +
                            "<p>ทางเราขอขอบพระคุณเป็นอย่างยิ่งที่ท่านได้สมัครเข้าร่วมเป็นผู้จัดส่งอาหารในระบบของเรา ทางทีมงานได้ตรวจสอบข้อมูลของท่านเรียบร้อยแล้ว และมีความยินดีอย่างยิ่งที่จะแจ้งให้ทราบว่า บัญชีผู้จัดส่งอาหารของท่านได้รับการอนุมัติให้เข้าใช้งานระบบเป็นที่เรียบร้อยแล้ว</p>" +
                            "<p>ท่านสามารถเข้าสู่ระบบเพื่อเริ่มปฏิบัติงานได้แล้ว ณ ตอนนี้</p>" +
                            "<p>ขอแสดงความนับถือ,<br>ทีมงาน ระบบจัดส่งอาหารร้านค้าภายในมหาวิทยาลัยแม่โจ้</p>";

            emailService.sendEmailHtml(rider.getEmail(), subject, body);
        }
    }

    // 💖 ส่วนการปฏิเสธไรเดอร์
    @Override
    public void rejectRider(String studentId, String reason) {
        Rider rider = riderRepository.findByStudentid(studentId)
                .orElseThrow(() -> new RuntimeException("ไม่พบชื่อผู้ใช้งาน: " + studentId));

        // 1. ส่งอีเมลแจ้งผลก่อน
        if (rider.getEmail() != null && !rider.getEmail().isEmpty()) {
            String subject = "แจ้งผลการพิจารณาการสมัครผู้จัดส่งอาหาร - " + rider.getFirstName() + " " + rider.getLastName();
            String body =
                    "<h1 style='color: #dc3545; font-size: 32px; font-weight: bold; text-align: center;'>【 ไม่อนุมัติ 】</h1>" +
                            "<p>เรียน คุณ " + rider.getFirstName() + " " + rider.getLastName() + ",</p>" +
                            "<p>ทางเราขอขอบพระคุณเป็นอย่างยิ่งที่ท่านได้สมัครเข้าร่วมเป็นผู้จัดส่งอาหารในระบบของเรา ทางทีมงานได้ตรวจสอบข้อมูลของท่านแล้ว ทางเราขออภัยที่ต้องแจ้งให้ทราบว่าบัญชีผู้จัดส่งของท่านยังไม่ผ่านการอนุมัติ</p>" +
                            "<div style='background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; border-left: 5px solid #dc3545; padding: 12px 16px; border-radius: 4px; margin: 15px 0;'>" +
                            "<strong>เหตุผล:</strong> " + reason +
                            "</div>" +
                            "<p>ท่านสามารถทำการสมัครสมาชิกใหม่อีกครั้งได้</p>" +
                            "<p>ขอแสดงความนับถือ,<br>ทีมงาน ระบบจัดส่งอาหารร้านค้าภายในมหาวิทยาลัย</p>";

            emailService.sendEmailHtml(rider.getEmail(), subject, body);
        }

        // 2. ลบข้อมูลออกจากฐานข้อมูล
        riderRepository.delete(rider);
    }
}