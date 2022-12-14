package com.oauth2.sample.web.payload;

import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import org.springframework.http.HttpStatus;

//{
//        "code": 200000,
//        "message": "ok",
//        "data": {
//        }
//}

@Getter
@Setter
public class ApiResponse<T> {
    private int code;
    private String message;
    private T data;

    @Builder
    public ApiResponse(HttpStatus code, String message, T data) {
        this.code = code.value();
        if(message == null) {
            this.message = code.getReasonPhrase();
        } else {
            this.message = message;
        }
        this.data = data;
    }
}
