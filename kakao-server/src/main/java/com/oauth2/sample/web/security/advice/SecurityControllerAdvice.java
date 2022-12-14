package com.oauth2.sample.web.security.advice;


import com.oauth2.sample.web.payload.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.InsufficientAuthenticationException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RequiredArgsConstructor
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class SecurityControllerAdvice {

    private final MessageSource messageSource;

    @ExceptionHandler({AuthenticationException.class})
    public ResponseEntity authenticationExceptionHandle(AuthenticationException exception) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                getApiException(exception.getLocalizedMessage())
        );
    }

    @ExceptionHandler({BadCredentialsException.class})
    public ResponseEntity badCredentialsExceptionHandle(AuthenticationException exception) {
        String message = messageSource.getMessage("AuthenticationException.badCredentials", null, exception.getLocalizedMessage(), null);

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                getApiException(message)
        );
    }

    @ExceptionHandler({UsernameNotFoundException.class})
    public ResponseEntity usernameNotFoundExceptionHandle(AuthenticationException exception) {
        String message = messageSource.getMessage("AuthenticationException.usernameNotFound", null, exception.getLocalizedMessage(), null);

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                getApiException(message)
        );
    }

    @ExceptionHandler({InsufficientAuthenticationException.class})
    public ResponseEntity insufficientAuthenticationExceptionHandle(AuthenticationException exception) {
        String message = messageSource.getMessage("AuthenticationException.Insufficient", null, exception.getLocalizedMessage(), null);

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                getApiException(message)
        );
    }

    private ApiException getApiException(String message) {
        return ApiException.builder()
                .errorCode(HttpStatus.UNAUTHORIZED)
                .errorDescription(message)
                .build();
    }
}
