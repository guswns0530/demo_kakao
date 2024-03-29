import React, {useMemo} from "react";
import style from "../../../css/MainPage.module.css"
import ProfileImage from "../../util/ProfileImage";
import {Link, useLocation, useParams} from "react-router-dom";
import Room from "../../../constants/Room";
import {useInviteOrCreateRoom} from "../../../lib/query";
import {toast} from "react-toastify";
import Chat from "../../../constants/Chat";

const MyChat = ({children}) => {
    return <div className={`${style.chat} ${style.me}`}>
        {children}
    </div>
}

const YouChat = ({children, user}) => {
    const location = useLocation()

    return <div className={`${style.chat} ${style.you}`}>
        <div className={style.c_pro}>
            <div className={style.image}>
                <Link to={"/app/profile/" + user.id} state={location.state}>
                    <ProfileImage profile_image_url={user.profile_image_url}/>
                </Link>
            </div>
            <div className={style.name}>{user.name}</div>
        </div>
        {children}
    </div>
}

const Block = ({chat, isLast, onContextMenu}) => {
    const {chat_id, content, read, date} = chat
    const {id} = useParams()

    return <div className={style.chat_block} key={chat_id}>
        <div className={style.chat_content} onContextMenu={(e) => onContextMenu(e, chat, id)}>
            <span>{content}</span>
            <div className={style.chat_info}>
                <div className={style.chat_read}>{read === 0 ? undefined : read}</div>
                {isLast && <div className={style.chat_data}>{date}</div>}
            </div>
        </div>
    </div>
}

const ChatDate = ({createAt}) => {
    const list = ['일', '월', '화', '수', '목', '금', '토']
    return (<div className={style.chat_notice}>
        <div
            className={style.chat_date}>{createAt.getFullYear()}년 {createAt.getMonth() + 1}월 {createAt.getDate()}일 {list[createAt.getDay()]}요일
        </div>
    </div>)
}

const JoinBlock = ({user: {name, id}, chat: {content, chat_id}, users}) => {
    const location = useLocation()
    const joinUser = JSON.parse(content)
    return (<div className={style.chat_notice} key={chat_id}>
            <div className={style.chat_date}>
                <Link to={"/app/profile/" + id} state={location.state}>{name}</Link>님이 <span> </span>
                {joinUser.map((email, i) => {
                    const {name, id} = users.find(user => user.email === email)
                    if (i === joinUser.length - 1) {
                        return <React.Fragment key={id}>
                            <Link to={"/app/profile/" + id} state={location.state}>{name}</Link>님
                        </React.Fragment>
                    }
                    return <React.Fragment key={id}>
                        <Link to={"/app/profile/" + id} state={location.state}>{name}</Link>님,<span> </span>
                    </React.Fragment>
                })}
                을 초대하였습니다.
            </div>
        </div>)
}

const LeaveBlock = ({user: {id, name, email}, chat, users}) => {
    const location = useLocation()
    const {room_status} = users.find(user => user.email === email)
    const {mutate} = useInviteOrCreateRoom(() => {
    }, (data) => {
        toast.error(data.response.data['error_description'])
        return true;
    })
    const {id: roomId} = useParams()

    const onClick = (e) => {
        e.preventDefault()
        mutate({
            roomId, users: [email]
        })
    }

    return (<div className={style.chat_notice} key={1}>
            <div className={style.chat_date}>
                <Link to={"/app/profile/" + id} state={location.state}>{name}</Link>님이 나갔습니다.<br/>
                {room_status === Room.status.REMOVE && <Link onClick={onClick}>채팅방으로 초대하기</Link>}
            </div>
        </div>)
}

const RemoveBlock = ({chat, isLast}) => {
    const {chat_id, read, date} = chat

    return <div className={style.chat_block} key={chat_id}>
        <div className={style.chat_content}>
            <span className={style.chat_content_remove}>
                <div className={style.chat_content_remove_icon}>
                    <span className="material-symbols-outlined">priority_high</span>
                </div>
                삭제된 메시지입니다.</span>
            <div className={style.chat_info}>
                <div className={style.chat_read}>{read === 0 ? undefined : read}</div>
                {isLast && <div className={style.chat_data}>{date}</div>}
            </div>
        </div>
    </div>
}


const ChatLog = ({children, chats, reader, users, user, content, onScroll, onContextMenu}) => {
    const [list, child] = useMemo(() => {
        const list = []
        const child = []
        chats.forEach(async (chat, i) => {
            const {chat_id, chat_status, chat_type, content, create_at, email} = chat
            const createAt = new Date(create_at)
            const date = `${createAt.amPm()} ${createAt.getHours() > 12 ? createAt.getHours() - 12 : createAt.getHours()}:${createAt.getMinutes() < 10 ? "0" + createAt.getMinutes() : createAt.getMinutes()}`
            let read = 0;

            reader.forEach(id => {
                if (id * 1 < chat_id * 1) read++
            })

            const chatObj = {date, read, content, chat_id, email, chat_status, chat_type, createAt}

            if (i - 1 >= 0 && chat_type !== 3) {
                const beforeChat = chats[i - 1]

                if (chat.email === beforeChat.email && beforeChat.chat_type != Chat.type.LEAVE && beforeChat.chat_type != Chat.type.JOIN && beforeChat.chat_type != Chat.type.FILE) {
                    if (createAt.isSame(new Date(beforeChat['create_at']))) {
                        child[child.length - 1].push(chatObj)
                        return
                    }
                }
            }

            const findUser = users.find(user => user.email === email)
            if (findUser) {
                list.push(findUser)
                child.push([chatObj])
            } else {
                list.push({
                    id: undefined, email: email, name: '알수 없음', profile_image_url: 1, // createAt:
                })
                child.push([chatObj])
            }
        })

        return [list, child]
    }, [chats, reader, users, user]);


    const data = useMemo(() => {
        return list.map((userInfo, i) => {
            const data = []
            const userChats = child[i]

            if (userChats[0].chat_type == Chat.type.JOIN) { // 접속
                data.push(<JoinBlock chat={userChats[0]} user={userInfo} key={i} users={users}/>)
            } else if (userChats[0].chat_type == Chat.type.LEAVE) { // 나감
                data.push(<LeaveBlock chat={userChats[0]} user={userInfo} key={i} users={users}/>)
            } else if (userInfo.email === user.email) { // 내가 보낸 메시지
                data.push(<MyChat style={style} key={i}>
                    {child[i].sort((a, b) => {
                        return a.chat_id - b.chat_id
                    }).map((chat, j) => {
                        chat.user = userInfo
                        if (chat.chat_status == Chat.status.REMOVE) {
                            return <RemoveBlock chat={chat} isLast={j === child[i].length - 1} key={chat.chat_id}/>
                        }
                        return <Block chat={chat} isLast={j === child[i].length - 1} key={chat.chat_id}
                                      onContextMenu={onContextMenu}/>
                    })}
                </MyChat>)
            } else { // 상대가 보낸 메시지
                data.push(<YouChat user={userInfo} style={style} key={i}>
                    {child[i].sort((a, b) => {
                        return a.chat_id - b.chat_id
                    }).map((chat, j) => {
                        chat.user = userInfo
                        if (chat.chat_status == Chat.status.REMOVE) {
                            return <RemoveBlock chat={chat} isLast={j === child[i].length - 1} key={chat.chat_id}/>
                        }
                        return <Block chat={chat} isLast={j === child[i].length - 1} key={chat.chat_id}
                                      onContextMenu={onContextMenu}/>
                    })}
                </YouChat>)
            }

            // chat date 넣어주기
            if (i + 1 < list.length && !child[i][0].createAt.isSameDate(child[i + 1][0].createAt)) {
                data.push(<ChatDate key={child[i][0].createAt} createAt={child[i][0].createAt}/>)
            } else if (child[i][0].chat_id === chats[chats.length - 1].chat_id) {
                data.push(<ChatDate key={child[i][0].createAt} createAt={child[i][0].createAt}/>)
            }

            return data
        })
    }, [list, child, chats, users]);

    return <div className={style.chat_log} ref={content} onScroll={onScroll}>
        {data}
        {children}
    </div>
}

export default ChatLog
