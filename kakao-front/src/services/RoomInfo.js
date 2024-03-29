import ProfileImage from "../component/util/ProfileImage";
import React from "react";
import Room from "../constants/Room";
import Chat from "../constants/Chat";

const roomService = (user, room) => {
    let {
        chat_content, chat_create_at, chat_status,
        chat_type,
        join_user_cnt, room_id, room_name, unread_cnt, users
    } = room
    const now = new Date()
    const createAt = new Date(chat_create_at)

    let date = ''

    if (createAt.isSameMonth(now)) {
        if (createAt.getDate() === now.getDate()) {
            date = `${createAt.amPm()} ${createAt.getHours() > 12 ? createAt.getHours() - 12 : createAt.getHours()}:${createAt.getMinutes() < 10 ? "0" + createAt.getMinutes() : createAt.getMinutes()}`
        } else if (createAt.getDate() === now.getDate() - 1) {
            date = '어제'
        } else {
            date = `${createAt.getFullYear()}-${createAt.getMonth() + 1}-${createAt.getDate()}`
        }
    } else {
        date = `${createAt.getFullYear()}-${createAt.getMonth() + 1}-${createAt.getDate()}`
    }

    if (room.room_type == Room.type.SOLO) {
        const name = user.name;
        const profileImageList = [<ProfileImage key={user.email} profile_image_url={user.profile_image_url}/>]

        if (chat_status * 1 === Chat.status.REMOVE * 1) {
            chat_content = '삭제된 메시지입니다.'
        }

        return {profileImageList, name, date, chat_content, join_user_cnt, room_id, unread_cnt, chat_status, chat_type}
    } else {
        const filterUser = users.filter(u => u.email !== user.email && u.room_status != Room.status.REMOVE)
        const name = room_name || filterUser.reduce((before, now) => {
            if (!before) {
                return now.name
            }
            return now.name + ', ' + before
        }, '')

        const profileImageList = filterUser.slice(0, 4).map(({email, profile_image_url}) => {
            return <ProfileImage key={email} profile_image_url={profile_image_url}/>
        })

        if (chat_status * 1 === Chat.status.REMOVE * 1) {
            chat_content = '삭제된 메시지입니다.'
        }

        return {profileImageList, name, date, chat_content, join_user_cnt, room_id, unread_cnt, chat_status, chat_type}
    }
}

export default roomService