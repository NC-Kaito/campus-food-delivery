package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.dtos.RiderDto;
import com.it22mjudelivery.springboot_api.v2.entities.Rider;

public interface RiderService {
    Rider doLoginRider(String studentId, String password);

    RiderDto getRiderByStudentId(String studentId);

    boolean doRegisterRider(RiderDto riderDto);

    boolean updateRiderStatus(String studentId, boolean isActive);

    boolean updateProfileRider(String studentId, String phone, String profileImage);
}
