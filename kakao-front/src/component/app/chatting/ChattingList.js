import React from "react";
import style from "../../../css/MainPage.module.css"

const ChattingList = ({data, onDoubleClick, handleContextMenu}) => {
    const list = data.map(room => {
        const {room_id, profileImageList, join_user_cnt, unread_cnt, chat_content, name, date} = room

        return (<li key={room_id} onDoubleClick={(e) => onDoubleClick(e, room_id)} onContextMenu={(e) => handleContextMenu(e, room)}>
            <div className={style.profile}>
                <div className={style.image}>
                    {profileImageList}
                </div>
                <div className={style.context}>
                    <div className={style.name}>{name}
                        {join_user_cnt > 2 && <div className={style.count}>{ join_user_cnt }</div>}
                    </div>
                    <div className={style.msg} style={{marginTop: "4px"}}>
                        {chat_content}
                    </div>
                </div>
                <div className={style.sub_info}>
                    <div className={style.date}>{date}</div>
                    {unread_cnt * 1 !== 0 && <div className={style.alert}>{unread_cnt >= 100 ? '99' : unread_cnt }</div>}
                </div>
            </div>
        </li>)
    })

    return (<ul>
        {list}
    </ul>)
}

export default ChattingList
