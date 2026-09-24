package com.it22mjudelivery.springboot_api.v1.services;

import com.it22mjudelivery.springboot_api.v1.dtos.AddonGroupRequestDTO;


import java.util.List;

public interface AddonService {
    public boolean createAddonGroupTemplate(AddonGroupRequestDTO request);

    public boolean updateAddonGroupTemplate(AddonGroupRequestDTO requestDTO);

    boolean deleteAddonGroup(Integer groupId);
}
