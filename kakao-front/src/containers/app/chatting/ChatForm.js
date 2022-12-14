import React, {useEffect, useRef, useState} from "react";
import ChatFormComponent from "../../../component/app/chatting/ChatForm";
import {useInsertChatText} from "../../../lib/query";

const ChatForm = ({roomId, content, block}) => {
    const inputRef = useRef()
    const [input, setInput] = useState('')

    const { mutate, isLoading } = useInsertChatText()

    useEffect(() => {
        inputRef.current.focus()
    }, [input]);

    const updateInputScroll = () => {
        const elem = inputRef.current
        elem.style.height = '0px'
        const {scrollHeight} = elem

        let line = scrollHeight / 18

        if (line > 5) {
            elem.style.overflowY = 'scroll'
            line = 5
        } else {
            elem.style.overflowY = 'hidden'
        }

        elem.style.height = line * 18 + 'px'
    }


    const onChange = (e) => {
        setInput(e.target.value)
        if (inputRef.current) {
            updateInputScroll()
        }
    }

    const onKeyDown = (e) => {
        if(e.keyCode === 13) {
            onSubmit(e)
        }
    }

    const onSubmit = (e) => {
        e.preventDefault()
        if(input.trim() === '') {
           return
        }
        mutate({roomId, content: input})
        setInput('')
        inputRef.current.style.height = '54px'
        inputRef.current.focus()
        content.current.scrollTop = 0
    }

    return <ChatFormComponent inputRef={inputRef} onChange={onChange} input={input} onSubmit={onSubmit} isLoading={isLoading} onKeyDown={onKeyDown} block={block}/>
}

export default ChatForm