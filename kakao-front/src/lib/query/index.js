import {useMutation} from "react-query";
import queryClient from "../../services/queryClient";

import {blockFriendToEmail, insertFriendToEmail, insertFriendToId, updateFriendName} from "../api/friend";

import {queryName as myInfoQueryName} from "../../pages/MainPage";
import {queryName as friendInfoQueryName} from "../../containers/app/friend/FriendList";
import {queryName as recommendFriendInfoQueryName} from "../../containers/app/friend/RecommendFriendList";
import {queryName as selectToUserId} from "../../containers/app/popup/ProfilePopup";
import {queryName as blockListQueryName} from "../../containers/app/setting/FriendSetting"
import {updateUserToEmail} from "../api/user";
import {insertChatText, readChat} from "../api/chat";
import {inviteOrCreateRoom, leaveRoom, updateRoom} from "../api/room";

export const useInsertFriend = (onSuccess, onError) => {
    return useMutation(async ({id, type}) => {
        if (type === 'id') {
            return insertFriendToId(id)
        }
        if (type === 'email') {
            return insertFriendToEmail(id)
        }
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }
            await queryClient.refetchQueries(selectToUserId)
            await queryClient.refetchQueries(friendInfoQueryName)
            await queryClient.refetchQueries(recommendFriendInfoQueryName)
            await queryClient.refetchQueries(blockListQueryName)
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    }, {})
}


export const useBlockFriend = (onSuccess, onError) => {
    return useMutation(async ({email}) => {
        return blockFriendToEmail(email)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }
            await queryClient.refetchQueries(selectToUserId)
            await queryClient.refetchQueries(friendInfoQueryName)
            await queryClient.refetchQueries(recommendFriendInfoQueryName)
            await queryClient.refetchQueries(blockListQueryName)
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useChangeNickname = (onSuccess, onError) => {
    return useMutation(async ({email, name}) => {
        return updateFriendName(email, name)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }
            await queryClient.refetchQueries(selectToUserId)
            await queryClient.refetchQueries(friendInfoQueryName)
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useUpdateUser = (onSuccess, onError) => {
    return useMutation(async (data) => {
        return updateUserToEmail(data)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }

            await queryClient.refetchQueries(myInfoQueryName)
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useInsertChatText = (onSuccess, onError) => {
    return useMutation(async ({roomId, content}) => {
        return insertChatText(roomId, content)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useReadChat = (onSuccess, onError) => {
    return useMutation(async (roomId) => {
        return readChat(roomId)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)

            }
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useInviteOrCreateRoom = (onSuccess, onError) => {
    return useMutation(async (data) => {
        return inviteOrCreateRoom(data)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }

        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useLeaveRoom = (onSuccess, onError) => {
    return useMutation(async (data) => {
        return leaveRoom(data)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }

        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}

export const useUpdateRoom = (onSuccess, onError) => {
    return useMutation(async ({roomId, roomName}) => {
        return updateRoom(roomId, roomName)
    }, {
        onSuccess: (async (data) => {
            if (onSuccess) {
                onSuccess(data)
            }
        }),
        onError: (error) => {
            if (onError) {
                onError(error)
            }
        }
    })
}