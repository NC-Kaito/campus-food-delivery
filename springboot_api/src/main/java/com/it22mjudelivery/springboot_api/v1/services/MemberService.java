package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v1.dtos.ReviewDto;
import com.it22mjudelivery.springboot_api.v1.entities.Member;
import com.it22mjudelivery.springboot_api.v1.entities.Review;

public interface MemberService {
    Member doLoginMember(String username, String password);

    boolean doRegisterMember(MemberDto memberDto);

    Member getMemberByUsername(String username);

    boolean doUpdateProfileMember(String username, String phone, String profileImg);

    Review addReview(ReviewDto reviewDto);

}
