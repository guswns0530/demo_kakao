package com.oauth2.sample.web.security.service;

import com.oauth2.sample.domain.user.repository.UserRepository;
import com.oauth2.sample.web.security.principal.UserPrincipal;
import com.oauth2.sample.web.security.dto.User;
import com.oauth2.sample.web.security.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/*@Service*/
@Slf4j
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new UsernameNotFoundException("유저를 찾을수 없습니다. : " + email)
                );

        return UserPrincipal.create(user);
    }

    @Transactional
    public UserDetails loadUserById(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(
                () -> new ResourceNotFoundException("유저를 찾을수 없습니다. :" + email)
        );

        return UserPrincipal.create(user);
    }
}

// 로그아웃 구현
