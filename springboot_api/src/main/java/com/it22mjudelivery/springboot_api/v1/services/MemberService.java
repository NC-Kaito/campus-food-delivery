package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.entities.Member;

public interface MemberService {
    Member doLoginMember(String username, String password);
}
