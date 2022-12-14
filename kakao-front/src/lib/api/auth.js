import client from "./client";

export const login = ({ email, password}) => {
    return client.post('/auth/login', {email, password})
}

export const register = ({ password, name}) => {
    return client.post('/auth/signup', {password, name})
}

export const getEmailVerify = (email) => {
    return client.post('/auth/email-verify', {email})
}

export const checkEmailVerify = (verifyCode) => {
    return client.post("/auth/email-confirm", verifyCode)
}

export const refreshToken = (jwtToken) => {
    return client.post('/auth/refresh', {oldAccessToken: jwtToken})
}