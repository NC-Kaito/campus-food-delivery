package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailAddOnDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDetailDto;
import com.it22mjudelivery.springboot_api.v1.dtos.AddOrderDto;
import com.it22mjudelivery.springboot_api.v1.entities.Order;
import com.it22mjudelivery.springboot_api.v1.entities.OrderDetail;
import com.it22mjudelivery.springboot_api.v1.entities.Orderdetailaddon;

public interface OrderService {
    boolean memberConfirmOrder(AddOrderDto addOrderDto);
}
