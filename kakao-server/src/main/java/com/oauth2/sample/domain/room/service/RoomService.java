package com.oauth2.sample.domain.room.service;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.json.JsonReadFeature;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.oauth2.sample.domain.chat.dto.ChatType;
import com.oauth2.sample.domain.chat.dto.Chat;
import com.oauth2.sample.domain.chat.dto.ReadUser;
import com.oauth2.sample.domain.chat.repository.ChatRepository;
import com.oauth2.sample.domain.room.dto.InviteUserToRoom;
import com.oauth2.sample.domain.room.dto.RoomInfo;
import com.oauth2.sample.domain.room.dto.RoomType;
import com.oauth2.sample.domain.room.repository.RoomRepository;
import com.oauth2.sample.domain.room.dto.InsertRoom;
import com.oauth2.sample.domain.room.request.InviteRoomRequest;
import com.oauth2.sample.domain.room.request.UpdateRoomRequest;
import com.oauth2.sample.domain.room.response.RoomInfoResponse;
import com.oauth2.sample.domain.room.response.JoinUser;
import com.oauth2.sample.domain.user.repository.UserRepository;
import com.oauth2.sample.web.security.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.RequestMapping;

import java.lang.reflect.Array;
import java.lang.reflect.Type;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

@Service
@RequestMapping
@RequiredArgsConstructor
@Slf4j
public class RoomService {
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final ChatRepository chatRepository;
    private final SimpMessagingTemplate messagingTemplate;


    public RoomInfoResponse selectRoom(String email, String roomId) {
        try {
            Optional<RoomInfo> roomInfoOf = roomRepository.selectRoom(email, roomId);

            RoomInfo roomInfo = roomInfoOf.orElseThrow(() -> {
                throw new BadRequestException("????????? ???????????????.");
            });

            return getRoomInfoResponse(roomInfo);
        } catch (Exception e) {
            throw new BadRequestException("????????? ???????????????.");
        }
    }


    public List<RoomInfoResponse> selectRoomList(String email) {
        List<RoomInfo> roomInfos = roomRepository.selectRoomList(email);

        Stream<RoomInfoResponse> roomInfoResponseStream = roomInfos.stream().map(roomInfo -> {
            return getRoomInfoResponse(roomInfo);
        });

        List<RoomInfoResponse> roomInfoResponseList = roomInfoResponseStream.collect(Collectors.toList());

        return roomInfoResponseList;
    }

    @Transactional
    public void updateRoom(UpdateRoomRequest request) {
        if (!roomRepository.existUser(request.getRoomId(), request.getEmail())) {
            throw new BadRequestException("????????? ????????????.");
        }

        boolean result = roomRepository.updateRoom(request);

        roomRepository.selectJoinUser(request.getRoomId()).forEach(joinUserEmail -> {
            messagingTemplate.convertAndSend("/queue/room/" + joinUserEmail  + "/update", request.getRoomId());
        });
    }

    // ??????
    @Transactional
    public RoomInfoResponse inviteUserToRoom(InviteRoomRequest inviteRoomRequest) {
        List<String> users = inviteRoomRequest.getUsers();

        // ?????? ?????? ??????
        users.stream().forEach(user -> {
            if (!userRepository.existByEmail(user)) {
                throw new BadRequestException("???????????? ?????? ???????????????.");
            }
        });

        // ??? ??????
        Optional<RoomInfo> roomInfoOf = roomRepository.selectRoom(inviteRoomRequest.getFromEmail(), inviteRoomRequest.getRoomId());
        // ?????? ???????????? ?????? ??????
        RoomInfo roomInfo = roomInfoOf.orElseGet(() -> {
            if (StringUtils.hasText(inviteRoomRequest.getRoomId())) {
                throw new BadRequestException("????????? ????????????.");
            }
            if (users.size() == 1) {
                throw new BadRequestException("????????? ???????????????.");
            }

            InsertRoom insertRoom = null;

            insertRoom = InsertRoom.builder()
                    .roomName(inviteRoomRequest.getRoomName())
                    .type(RoomType.GROUP)
                    .build();

            boolean isInsert = roomRepository.insertRoom(insertRoom);
            if (!isInsert) {
                throw new BadRequestException("??? ????????? ????????? ?????????????????????.");
            }

            users.add(inviteRoomRequest.getFromEmail());

            return RoomInfo.builder()
                    .roomId(insertRoom.getRoomId())
                    .roomType(RoomType.GROUP)
                    .build();
        });

        // ???????????? ?????? ???????????? ?????? -> ????????? ?????? ??????
        if (roomInfo.getRoomType() == RoomType.PERSON) {
            InsertRoom insertRoom = InsertRoom.builder()
                    .roomName(inviteRoomRequest.getRoomName())
                    .type(RoomType.GROUP)
                    .build();

            boolean isInsert = roomRepository.insertRoom(insertRoom);
            if (!isInsert) {
                throw new BadRequestException("??? ????????? ????????? ?????????????????????.");
            }

            // ???????????? ?????? ?????? ??????
            try {
                List<JoinUser> userList = new ObjectMapper().readValue(roomInfo.getUsers(), new TypeReference<List<JoinUser>>() {
                });

                userList.stream().forEach((user) -> {
                    users.add(user.getEmail());
                });
            } catch (Exception ex) {
                throw new BadRequestException("?????? ?????? ?????? ??????????????? ???????????????");
            }

            roomInfo = RoomInfo.builder()
                    .roomId(insertRoom.getRoomId())
                    .build();
        }

        String roomId = roomInfo.getRoomId();
        String email = inviteRoomRequest.getFromEmail();

        joinRoom(users, roomId, email);

        RoomInfo room = roomRepository.selectRoom(email, roomId).orElseThrow(() -> {
            throw new BadRequestException("????????? ????????? ?????????????????????.");
        });

        return getRoomInfoResponse(room);
    }

    @Transactional
    public void leaveRoom(String roomId, String email) {
        if (!roomRepository.existUser(roomId, email)) {
            throw new BadRequestException("?????? ???????????? ????????????.");
        }

        SimpleDateFormat sdf = new SimpleDateFormat("YYYY-MM-dd HH:mm:ss");
        String nowStr = sdf.format(new Date());

        // chat ????????? ??????
        Chat chat = Chat.builder()
                .roomId(roomId)
                .email(email)
                .createAt(nowStr)
                .chatType(ChatType.LEAVE)
                .build();


        boolean insertChatResult = chatRepository.insertChat(chat);
        // join_users status ????????? ??????
        boolean removeJoinUserResult = roomRepository.removeJoinUser(roomId, email);
        // read_users ??????
        boolean removeReadUserResult = chatRepository.removeReadUser(roomId, email);

        if (!insertChatResult || !removeJoinUserResult || !removeReadUserResult) {
            throw new BadRequestException("?????? ???????????? ?????????????????????.");
        }

        roomRepository.selectJoinUser(roomId).forEach(joinUserEmail -> {
            messagingTemplate.convertAndSend("/queue/chat/" + joinUserEmail  + "/leave", chat);
        });
    }

    private RoomInfoResponse getRoomInfoResponse(RoomInfo roomInfo) {
        List<JoinUser> arrayList = null;
        try {
            ObjectMapper mapper = JsonMapper.builder()
                    .enable(JsonReadFeature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER)
                    .build();
            arrayList = mapper.readValue(roomInfo.getUsers(), new TypeReference<List<JoinUser>>() {
            });
        } catch (Exception ex) {
            ex.printStackTrace();
            throw new BadRequestException("?????? ?????? ?????? ??????????????? ???????????????");
        }
        return RoomInfoResponse.builder()
                .roomId(roomInfo.getRoomId())
                .roomName(roomInfo.getRoomName())
                .roomCreateAt(roomInfo.getRoomCreateAt())
                .chatCreateAt(roomInfo.getChatCreateAt())
                .chatContent(roomInfo.getChatContent())
                .chatStatus(roomInfo.getChatStatus())
                .chatType(roomInfo.getChatType())
                .unreadCnt(roomInfo.getUnreadCnt())
                .users(arrayList)
                .roomType(roomInfo.getRoomType())
                .joinUserCnt(roomInfo.getJoinUserCnt()).build();
    }

    private void joinRoom(List<String> users, String roomId, String email) {
        SimpleDateFormat sdf = new SimpleDateFormat("YYYY-MM-dd HH:mm:ss");
        String nowStr = sdf.format(new Date());
        Chat insertChat = null;

        try {
            users.stream().forEach(user -> {
                InviteUserToRoom inviteUserToRoom = InviteUserToRoom.builder()
                        .roomId(roomId)
                        .email(user)
                        .createAt(nowStr)
                        .build();
                boolean insertResult = roomRepository.inviteUserToRoom(inviteUserToRoom);
                if (!insertResult) {
                    throw new BadRequestException("??? ?????? ????????? ?????????????????????.");
                }
            });

             insertChat = Chat.builder()
                    .email(email)
                    .content(new ObjectMapper().writeValueAsString(users.stream().filter(user -> !user.equals(email)).collect(Collectors.toList())))
                    .createAt(nowStr)
                    .chatType(ChatType.JOIN)
                    .roomId(roomId)
                    .build();

            boolean insertChatResult = chatRepository.insertChat(insertChat);
            if (!insertChatResult) {
                throw new BadRequestException("??? ?????? ????????? ?????????????????????.");
            }

            String chatId = insertChat.getChatId();
            users.stream().forEach(user -> {
                ReadUser readUser = ReadUser.builder()
                        .chatId(chatId)
                        .roomId(roomId)
                        .email(user)
                        .createAt(nowStr)
                        .build();

                boolean insertReadUserResult = chatRepository.insertReadUser(readUser);
                if (!insertReadUserResult) {
                    throw new BadRequestException("??? ?????? ????????? ?????????????????????.");
                }
            });
        } catch (DuplicateKeyException ex) {
            throw new BadRequestException("?????? ????????? ????????? ???????????????. ?????? ????????? ?????????.");
        } catch (Exception ex) {
            throw new BadRequestException(ex.getMessage());
        }

        Chat finalInsertChat = insertChat;

        roomRepository.selectJoinUser(roomId).forEach(joinUserEmail -> {
            messagingTemplate.convertAndSend("/queue/chat/" + joinUserEmail  + "/join", finalInsertChat);
        });
    }

    public List<String> selectReader(String email, String roomId) {
        roomRepository.selectRoom(email, roomId).orElseThrow(() -> {
            throw new BadRequestException("????????? ????????????.");
        });

        return roomRepository.selectReaderChat(roomId);
    }
}
