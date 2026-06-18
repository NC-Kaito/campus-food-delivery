package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Rider;

public interface RiderService {
    Rider doLoginRider(String studentId, String password);

    RiderDto getRiderByStudentId(String studentId);

    boolean doRegisterRider(RiderDto riderDto);

    boolean updateRiderStatus(String studentId, boolean isActive);
}
