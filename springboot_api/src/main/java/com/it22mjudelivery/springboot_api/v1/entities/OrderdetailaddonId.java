package com.it22mjudelivery.springboot_api.v1.entities;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderdetailaddonId implements Serializable {
    private int orderDetail;
    private int menuaddondetail;
}
