import React, {useRef, useState} from "react";

import FriendInfoComponent from "../../../component/app/friend/FriendList";
import {useQuery} from "react-query";
import {selectFriendList} from "../../../lib/api/friend";
import LoadingFriendList from "../../../component/app/friend/LoadingFriendList";
import {useDispatch, useSelector} from "react-redux";
import ErrorHandler from "../../handler/ErrorHandler";
import searchServiceToFriend from "../../../services/searchService";
import {Item, Menu, Separator, useContextMenu} from "react-contexify";
import {useLocation, useNavigate} from "react-router-dom";
import {useBlockFriend, useChangeNickname} from "../../../lib/query";
import style from "../../../css/MainPage.module.css";
import {openPopup} from "../../../modules/popup";

export const queryName = "selectFriendList"
export const menuId = "FriendInfoMenuId"

const FriendList = () => {
    const dispatch = useDispatch()
    const inputRef = useRef()
    const location = useLocation()
    const {search, friends} = useSelector(({form, friend}) => ({
        search: form.friend.search,
        friends: friend.friends
    }))
    const [isMore, setMore] = useState(true)
    const {show} = useContextMenu({
        id: menuId
    })
    const navigate = useNavigate()
    const {mutate} = useBlockFriend();
    const {mutate: updateNickMutate} = useChangeNickname();

    const onProfileClick = (e, room_id) => {
        const [x, y] = [e.pageX, e.pageY]
        navigate("/app/chatting/" + room_id, {state: {...location.state, locate: {x, y}}})
    }
    const onClick = (e) => {
        e.preventDefault()
        setMore(!isMore)
    }
    const handleContextMenu = (e, user) => {
        e.preventDefault()
        show(e, {
            props: () => ({
                user
            })
        })
    }
    const goProfile = (e) => {
        const user = e.props().user
        const [x, y] = [e.event.pageX, e.event.pageY]
        navigate("/app/profile/" + user.id, {state: {...location.state, locate: {x, y}}})
    }
    const onBlock = (e) => {
        const user = e.props().user

        const action = openPopup({
            element: (<>
                <header className={style.center}>
                    ?????????????????????????
                </header>
                <div className={style.info}>
                    ???????????? ????????? ????????? ???????????? ?????? ??? ????????? <br/>
                    ?????? ???????????? ???????????????.
                    <br/>
                    <br/>
                    (?????? ????????? ???????????? ??? ??? ????????????)
                </div>
            </>),
            submit: () => {
                mutate({email: user.email})

                return true
            }
        })
        dispatch(action)
    }

    const changeName = (e) => {
        const user = e.props().user

        const action = openPopup({
            element: <InputForm user={user} inputRef={inputRef}/>,

            submit: () => {
                const value = inputRef.current.value
                if(value) {
                    updateNickMutate({
                        email: user.email, name: inputRef.current.value
                    })
                } else {
                    updateNickMutate({
                        email: user.email, name: user.realname
                    })
                }

                return true
            }
        })
        dispatch(action)
    }
    const onProfileClickItem = (e) => {
        const {user} = e.props()
        const {event} = e

        const [x, y] = [event.pageX, event.pageY]

        navigate("/app/chatting/" + user.room_id, {state: {...location.state, locate: {x, y}}})
    }

    const filterData = searchServiceToFriend(friends, search)

    return (<>
        <FriendInfoComponent data={filterData} isMore={isMore} onClick={onClick} onContextMenu={handleContextMenu} onProfileClick={onProfileClick}/>
        <Menu id={menuId} animation={false}>
            <Item onClick={onProfileClickItem}>????????????</Item>
            <Separator/>
            <Item onClick={goProfile}>????????? ??????</Item>
            <Item onClick={changeName}>?????? ??????</Item>
            <Separator/>
            <Item onClick={onBlock}>??????</Item>
        </Menu>
    </>)
}

const InputForm = ({user, inputRef}) => {
    const [input, setInput] = useState(user.name || '')

    const changeInput = (e) => {
        const value = e.target.value
        if (value.length <= 20) {
            setInput(value)
        }
    }

    return (<>
        <header className={style.left}>
            ????????? ????????? ??????????????????
        </header>
        <div className={style.layer_input}>
            <input type="text" placeholder={input} value={input} onChange={changeInput} ref={inputRef}/>
            <span className={style.counter}> {input.length}/20 </span>
            <p>????????? ????????? ?????? : {user.realname}</p>
        </div>
    </>)
}

export default FriendList
