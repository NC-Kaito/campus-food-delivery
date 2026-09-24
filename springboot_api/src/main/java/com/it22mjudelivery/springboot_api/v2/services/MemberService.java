package com.it22mjudelivery.springboot_api.v2.services;

import com.it22mjudelivery.springboot_api.v2.dtos.MemberDto;
import com.it22mjudelivery.springboot_api.v2.dtos.ReviewDto;
import com.it22mjudelivery.springboot_api.v2.entities.Member;
import com.it22mjudelivery.springboot_api.v2.entities.Review;

public interface MemberService {
    Member doLoginMember(String username, String password);

    boolean doRegisterMember(MemberDto memberDto);

    Member getMemberByUsername(String username);

    boolean updateLocationMember(String username, double latitude, double longitude, String location);

    boolean doUpdateProfileMember(String username, String firstName, String lastName, String phone, String profileImg);

    Review addReview(ReviewDto reviewDto);

    Review getReviewByOrderId(int orderId);

}
