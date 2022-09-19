package com.oauth2.sample.web.advice;

import com.oauth2.sample.web.payload.ApiException;
import com.oauth2.sample.web.payload.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;

@RestControllerAdvice
@RequiredArgsConstructor
public class ControllerAdvice {

    private MessageMapping messageMapping;

    @ExceptionHandler( { Exception.class })
    public ResponseEntity defaultExceptionHandler(Exception exception) {
        ApiException apiResponse = ApiException.builder()
                .code(HttpStatus.BAD_REQUEST)
                .message(exception.getMessage())
                .build();

        return ResponseEntity.ok().body(apiResponse);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity methodArgumentNotValidExceptionHandle(MethodArgumentNotValidException exception) {
        BindingResult bindingResult = exception.getBindingResult();
        List<FieldError> result = bindingResult.getFieldErrors();
        
        result.stream().forEach(error -> {
            System.out.println("error.getDefaultMessage() = " + error.getDefaultMessage());
            System.out.println("error.getField() = " + error.getField());
            System.out.println("error.getRejectedValue() = " + error.getRejectedValue());
        });
        

        return ResponseEntity.ok().body(
                ApiException.builder()
                        .code(HttpStatus.BAD_REQUEST)
                        .message(result.toString())
                        .build()
        );
    }
}