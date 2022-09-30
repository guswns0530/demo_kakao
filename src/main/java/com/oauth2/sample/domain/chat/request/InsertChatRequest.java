package com.oauth2.sample.domain.chat.request;

import com.oauth2.sample.domain.chat.dto.ChatType;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Null;

@Getter
@Setter
@Builder
public class InsertChatRequest {
    @NotBlank( message = "필수값이 비어있습니다.")
    private String roomId;

    @NotBlank( message = "필수값이 비어있습니다.")
    private String content;
}
