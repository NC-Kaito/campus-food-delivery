package com.it22mjudelivery.springboot_api.v1.dtos;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.DayOfWeek;
import java.time.LocalTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class OpeningHourDto {
    private DayOfWeek dayOfWeek;
    private LocalTime opentime;
    private LocalTime closetime;

    @JsonProperty("open")
    private boolean open;
}