package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddonGroupRequestDTO;
import com.it22mjudelivery.springboot_api.v1.entities.Addonmenu;

import java.util.List;

public interface AddonService {
    public boolean createAddonGroupTemplate(AddonGroupRequestDTO request);

    public boolean updateAddonGroupTemplate(AddonGroupRequestDTO requestDTO);

    List<Addonmenu> searchAddonByName(String keyword);
}
