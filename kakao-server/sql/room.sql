/*create table kakao_rooms
(
    room_id   INTEGER,
    name      varchar2(50),
    type      INTEGER,
    status    INTEGER,
    createAt  DATE,
    updateAt  DATE,
    reserved1 VARCHAR2(300),
    reserved2 VARCHAR2(300),
    reserved3 VARCHAR2(300),
    constraint kakao_rooms_pk primary key (room_id)
);*/

-- 에러 있음 --

with CUTOFF_RS as (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      and from_id = FR.from_id
                                      and to_id = FR.to_id) <= 0 then '1'
                              else '2'
                              end as CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010212@naver.com')

select A.ROOM_ID,
       nvl(A.NAME, LISTAGG(nvl(DECODE(C.CUTOFF_RS, 1, C.nickname, null), D.NAME), ', ') within group (
           order by
               C.nickname,
               D.NAME
           ))                                         as NAME,
       nvl(A.NAME, LISTAGG(D.EMAIL, ', ') within group (
           order by
               C.nickname,
               D.NAME
           ))                                         as USERID,
       LISTAGG(nvl(D.EMAIL, 'null'), ', ') within group
           (
           order by
               C.nickname,
               D.NAME
           )                                          as NAME,
       count(B.EMAIL) + 1                             as CNT,
       DECODE(E.CHAT_STATUS, 1, E.CHAT_CONTENT, null) as CHAT_CONTENT,
       E.CHAT_TYPE,
       E.CHAT_STATUS,
       E.CHAT_CREATEAT,
       sum((select count(*)
            from kakao_chats G
            where A.ROOM_ID = G.ROOM_ID
              and G.chat_id > F.chat_id))             as UNREAD_CNT
from kakao_rooms A
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          group by E.ROOM_ID) E
                         on A.ROOM_ID = E.ROOM_ID
         join kakao_join_users B on A.ROOM_ID = B.ROOM_ID
         left outer join CUTOFF_RS C on B.EMAIL = C.TO_ID
         left outer join kakao_users D on B.EMAIL = D.EMAIL
         join kakao_read_users F on A.ROOM_ID = F.ROOM_ID
    and B.EMAIL = F.EMAIL
where B.EMAIL != 'y2010212@naver.com'
group by A.ROOM_ID,
         A.NAME,
         E.CHAT_CONTENT,
         E.CHAT_TYPE,
         E.CHAT_STATUS,
         E.CHAT_CREATEAT
order by CHAT_CREATEAT asc;


-- 최종 --
with CUTOFF_RS as (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      and from_id = FR.from_id
                                      and to_id = FR.to_id) <= 0 then '1'
                              else '2'
                              end as CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010212@naver.com')

select A.room_id                                                                       as ROOM_ID,
       nvl(A.NAME, LISTAGG(nvl(DECODE(C.CUTOFF_RS, 1, C.nickname, null), D.NAME),
                           ', ') within group ( order by C.nickname, D.NAME))          as ROOM_NAME,
       nvl(A.NAME, LISTAGG(D.EMAIL, ', ') within group ( order by C.nickname, D.NAME)) as EMAILS,
       count(B.EMAIL) + 1                                                              as JOIN_USER_CNT,
       DECODE(E.CHAT_STATUS, 1, E.CHAT_CONTENT, null)                                  as CHAT_CONTENT,
       E.CHAT_TYPE,
       E.CHAT_STATUS,
       E.CHAT_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = A.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = 'y2010212@naver.com'
                             and status in (1, 2)))                                    as UNREAD_CNT
from KAKAO_ROOMS A
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                          group by E.ROOM_ID) E on A.ROOM_ID = E.ROOM_ID
         join KAKAO_JOIN_USERS B on A.ROOM_ID = B.ROOM_ID
         left outer join CUTOFF_RS C on B.EMAIL = C.TO_ID
         left outer join KAKAO_USERS D on B.EMAIL = D.EMAIL
where B.EMAIL != 'y2010212@naver.com'
  and A.STATUS = 1
group by A.ROOM_ID,
         A.NAME,
         E.CHAT_CONTENT,
         E.CHAT_TYPE,
         E.CHAT_STATUS,
         E.CHAT_CREATEAT
order by CHAT_CREATEAT desc;


-- 방 생성 -> 후에 join_user insert *****
INSERT INTO KAKAO_ROOMS
    (ROOM_ID, NAME, TYPE, STATUS, CREATEAT)
VALUES (KAKAO_ROOMS_SEQ.NEXTVAL, '', 1, 1, SYSDATE);

commit;

-- 삭제 ( 필요 여부 )
-- update
--     KAKAO_ROOMS
-- set STATUS = 2
-- where ROOM_ID = ?;


-- 1. 지금 현재 참가하고 있는 룸 조회
-- 2. 마지막에 전달된 채팅조회 ( 메시지 , FILE ) 첫메시지가 없으면 조회안되게
with CUTOFF_RS as (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      and from_id = FR.from_id
                                      and to_id = FR.to_id) <= 0 then '1'
                              else '2'
                              end as CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010214@naver.com')
select C.room_id                                                                  as ROOM_ID,
       '[' || nvl(C.NAME, LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ') within group ( order by E.nickname, F.NAME)) || ']' as USERS,
       count(D.EMAIL) + 1                                                         as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                             as CHAT_CONTENT,
       to_char(G.CHAT_TYPE)                                                       as CHAT_TYPE,
       to_char(G.CHAT_STATUS)                                                     as CHAT_STATUS,
       G.CHAT_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = C.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = 'y2010214@naver.com'
                             and status in (1, 2)))                               as UNREAD_CNT
from kakao_join_users B
         join kakao_rooms C on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010212@naver.com'
  and D.EMAIL != B.EMAIL
  and G.room_id is not null
group by C.ROOM_ID,
         C.NAME,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT
order by CHAT_CREATEAT desc;


with CUTOFF_RS as (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      and from_id = FR.from_id
                                      and to_id = FR.to_id) <= 0 then '1'
                              else '2'
                              end as CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010214@naver.com')
select C.room_id                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']' as USERS,
       count(D.EMAIL) + 1                                             as JOIN_USER_CNT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010214@naver.com'
  and D.EMAIL != B.EMAIL
  and C.ROOM_ID = 3
group by C.ROOM_ID,
         C.NAME;
update KAKAO_ROOMS
set name = 'test'
where ROOM_ID = 3;


-- exist in room
select 1
from KAKAO_JOIN_USERS A
where A.EMAIL = 'y2010212@naver.com'
  and A.ROOM_ID = 3;

insert into KAKAO_ROOMS (ROOM_ID, NAME, TYPE, STATUS, CREATEAT)
values (KAKAO_ROOMS_SEQ.nextval, null, 2, 1, sysdate);
insert into KAKAO_JOIN_USERS (EMAIL, ROOM_ID, STATUS, CREATEAT)
values ('', '', 1, sysdate);

update KAKAO_JOIN_USERS
set STATUS = 2
where EMAIL = ''
  and ROOM_ID = '';

case when (select count(*)
        from kakao_friends
        where STATUS = 2

                AND from_id = FR.from_id
                AND to_id = FR.to_id

        ) <= 0 then '1'
        else '2'
END AS CUTOFF_RS
        from kakao_friends FR
        where

                from_id = 'y2010214@naver.com')


WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2

                                      AND from_id = FR.from_id
                                      AND to_id = FR.to_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010214@naver.com')


select C.room_id                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']' as USERS,
       C.type                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                 as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                                         AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                                       AS CHAT_STATUS,
       NVL(G.CHAT_CREATEAT, null)                                     AS CHAT_CREATEAT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010214@naver.com'
  and C.ROOM_ID = '4'
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT

select KAKAO_ROOMS_SEQ.nextval
from dual;

WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2

                                      AND from_id = FR.from_id
                                      AND to_id = FR.to_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010214@naver.com')


select C.room_id                                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']'                 as USERS,
       C.type                                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                                 as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                                                         AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                                                       AS CHAT_STATUS,
       NVL2(G.CHAT_CREATEAT, to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS'), null) as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                                   as ROOM_CREATEAT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'y2010214@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010214@naver.com'
  and C.ROOM_ID = '3'
  and B.STATUS = 1
  and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT;

-- MERGE
MERGE INTO KAKAO_JOIN_USERS A
USING (SELECT 'y2010214@naver.com' AS EMAIL, /*이메일 */
              '40'                 AS ROOM_ID
       from dual) B
ON (A.EMAIL = B.EMAIL and A.ROOM_ID = B.ROOM_ID)
WHEN MATCHED THEN
    UPDATE
    SET A.STATUS   = 2,
        A.CREATEAT = sysdate
WHEN NOT MATCHED THEN
    INSERT (ROOM_ID, EMAIL, STATUS, CREATEAT)
    VALUES (B.ROOM_ID, B.EMAIL, 1, sysdate);

MERGE
INTO KAKAO_JOIN_USERS A
USING (SELECT 'y2010214@naver.com' AS EMAIL,
              '46'                 AS ROOM_ID,
              to_date('2022-10-12 10:05:29', 'YYYY-MM-DD HH24:MI:SS')
                                   AS CREATEAT
       from dual) B
ON (A.EMAIL = B.EMAIL and A.ROOM_ID = B.ROOM_ID)
WHEN MATCHED THEN
    UPDATE
    SET A.STATUS   = 1,
        A.CREATEAT = B.CREATEAT
WHEN NOT MATCHED THEN
    INSERT
    (ROOM_ID,
     EMAIL,
     STATUS,
     CREATEAT)
    VALUES (B.ROOM_ID, B.EMAIL, 1, B.CREATEAT) MERGE
INTO KAKAO_JOIN_USERS A
USING (SELECT 'y2010214@naver.com' AS EMAIL,
              '46'                 AS ROOM_ID,
              to_date('2022-10-12 10:17:19', 'YYYY-MM-DD HH24:MI:SS')
                                   AS CREATEAT
       from dual) B
ON (A.EMAIL = B.EMAIL and A.ROOM_ID = B.ROOM_ID)
WHEN MATCHED THEN
UPDATE
    SET A .STATUS = 1,
    A.CREATEAT = B.CREATEAT
    WHEN NOT MATCHED THEN
INSERT
    ( ROOM_ID ,
        EMAIL
        ,
        STATUS
        ,
        CREATEAT)
    VALUES
    (B.ROOM_ID, B.EMAIL, 1, B.CREATEAT)

WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      AND from_id = FR.from_id
                                      AND to_id = FR.to_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010212@naver.com')


select C.room_id                                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '",' ||
                   ' "lastReadChat" : "' || G.CHAT_ID || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']'                 as USERS,
       C.type                                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                                 as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                                                         AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                                                       AS CHAT_STATUS,
       NVL2(G.CHAT_CREATEAT, to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS'), null) as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                                   as ROOM_CREATEAT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'y2010214@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010212@naver.com'
  and C.ROOM_ID = '46'
  and B.STATUS = 1
  and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT

WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      AND from_id = FR.from_id
                                      AND to_id = FR.to_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'ury0530@naver.com')


select C.room_id                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']' as USERS,
       C.type                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                 as CHAT_CONTENT,
       G.CHAT_TYPE,
       G.CHAT_STATUS,
       to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS')              as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                   as ROOM_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = C.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = 'ury0530@naver.com'
                             and status in (1, 2)))                   as UNREAD_CNT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'y2010214@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = ?
  and G.room_id is not null
  and B.STATUS = 1
  and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT
order by CHAT_CREATEAT desc


WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      AND from_id = FR.from_id
                                      AND to_id = FR.to_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'ury0530@naver.com')


select C.room_id                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                   ' "profileImageUrl" : "' || F.profile_image_url || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']' as USERS,
       C.type                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                 as CHAT_CONTENT,
       G.CHAT_TYPE,
       G.CHAT_STATUS,
       to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS')              as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                   as ROOM_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = C.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = 'ury0530@naver.com'
                             and status in (1, 2)))                   as UNREAD_CNT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'ury0530@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'ury0530@naver.com'
  and G.room_id is not null
  and B.STATUS = 1
  and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT
order by CHAT_CREATEAT desc

select FR.*,
       case
           when (select count(*)
                 from kakao_friends
                 where STATUS = 2

                   AND from_id = FR.to_id
                   AND to_id = FR.from_id) <= 0 then '1'
           else '2' END AS CUTOFF_RS
from kakao_friends FR
where from_id = 'y2010213@naver.com';


WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2

                                      AND from_id = FR.to_id
                                      AND to_id = FR.from_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010213@naver.com')
select C.room_id                                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(E.CUTOFF_RS, 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(E.CUTOFF_RS, 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                   ' "profileImageUrl" : "' || DECODE(E.CUTOFF_RS, 1, F.profile_image_url, null) || '",' ||
                   ' "status" : "' || NVL(E.status, 0) || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']'                 as USERS,
       C.type                                                                         as ROOM_TYPE,
       count(D.EMAIL)                                                                 as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                                 as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                                                         AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                                                       AS CHAT_STATUS,
       NVL2(G.CHAT_CREATEAT, to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS'), null) as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                                   as ROOM_CREATEAT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'y2010213@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010213@naver.com'
  and C.ROOM_ID = '17'
  and B.STATUS = 1
  and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT

WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      AND from_id = FR.to_id
                                      AND to_id = FR.from_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = 'y2010213@naver.com')


select C.room_id                                                                      as ROOM_ID,
       nvl(C.NAME, '')                                                                as ROOM_NAME,
       '[' || LISTAGG(
                   '{' ||
                   ' "id" : "' || F.ID || '",' ||
                   ' "name" : "' || nvl(DECODE(NVL(E.CUTOFF_RS, 1), 1, E.nickname, null), F.NAME) || '",' ||
                   ' "email" : "' || D.EMAIL || '",' ||
                   ' "message" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.MESSAGE, null) || '",' ||
                   ' "provider" : "' || F.PROVIDER || '",' ||
                   ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                   ' "profileImageUrl" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.profile_image_url, null) || '",' ||
                   ' "roomStatus" : "' || NVL(D.status, 0) || '",' ||
                   ' "friendStatus" : "' || NVL(E.status, 0) || '"' ||
                   '}', ', ')
                   within group ( order by E.nickname, F.NAME) || ']'                 as USERS,
       C.type                                                                         as ROOM_TYPE,
       sum(case when D.STATUS = '1' then 1 else 0 end)                                as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)                                 as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                                                         AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                                                       AS CHAT_STATUS,
       NVL2(G.CHAT_CREATEAT, to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS'), null) as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')                                   as ROOM_CREATEAT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CONTENT,
                                 max(E.type) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_TYPE,
                                 max(E.STATUS) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_STATUS,
                                 max(E.CREATEAT) keep (
                                     DENSE_RANK last
                                     order by
                                         E.CREATEAT,
                                         E.CHAT_ID
                                     ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = 'y2010213@naver.com'
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         left outer join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = 'y2010213@naver.com'
  and C.ROOM_ID = '60'
  and B.STATUS = 1
--         and D.STATUS = 1
group by C.ROOM_ID,
         C.NAME,
         C.TYPE,
         C.CREATEAT,
         G.CHAT_CONTENT,
         G.CHAT_TYPE,
         G.CHAT_STATUS,
         G.CHAT_CREATEAT


WITH CUTOFF_RS AS (select FR.*,
                          case
                              when (select count(*)
                                    from kakao_friends
                                    where STATUS = 2
                                      AND from_id = FR.to_id
                                      AND to_id = FR.from_id) <= 0 then '1'
                              else '2' END AS CUTOFF_RS
                   from kakao_friends FR
                   where from_id = '1')
select C.room_id                                       as ROOM_ID,
       nvl(C.NAME, '')                                 as ROOM_NAME,
       '[' || LISTAGG('{' || ' "id" : "' || F.ID || '",' || ' "name" : "' ||
                      nvl(DECODE(NVL(E.CUTOFF_RS, 1), 1, E.nickname, null), F.NAME) || '",' || ' "email" : "' ||
                      D.EMAIL || '",' || ' "message" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.MESSAGE, null) || '",' ||
                      ' "provider" : "' || F.PROVIDER || '",' || ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                      ' "profileImageUrl" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.profile_image_url, null) || '",' ||
                      ' "roomStatus" : "' || NVL(D.status, 0) || '",' || ' "friendStatus" : "' || NVL(E.status, 0) ||
                      '"' || '}',
                      ', ') within group ( order by E.nickname, F.NAME) ||
       ']'                                             as USERS,
       C.type                                          as ROOM_TYPE,
       sum(case when D.STATUS = '1' then 1 else 0 end) as JOIN_USER_CNT,
       DECODE(G.CHAT_STATUS, 1, G.CHAT_CONTENT, null)  as CHAT_CONTENT,
       NVL(G.CHAT_TYPE, null)                          AS CHAT_TYPE,
       NVL(G.CHAT_STATUS, null)                        AS CHAT_STATUS,
       NVL2(G.CHAT_CREATEAT, to_char(G.CHAT_CREATEAT, 'YYYY-MM-DD HH24:MI:SS'),
            null)                                      as CHAT_CREATEAT,
       to_char(C.CREATEAT, 'YYYY-MM-DD HH24:MI:SS')    as ROOM_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = C.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = ?
                             and status in (1, 2)))    as UNREAD_CNT
from kakao_join_users B
         join kakao_rooms C
              on B.ROOM_ID = C.ROOM_ID
         left outer join (select E.ROOM_ID,
                                 max(E.CONTENT) keep ( DENSE_RANK last order by E.CREATEAT, E.CHAT_ID )  CHAT_CONTENT,
                                 max(E.type) keep ( DENSE_RANK last order by E.CREATEAT, E.CHAT_ID )     CHAT_TYPE,
                                 max(E.STATUS) keep ( DENSE_RANK last order by E.CREATEAT, E.CHAT_ID )   CHAT_STATUS,
                                 max(E.CREATEAT) keep ( DENSE_RANK last order by E.CREATEAT, E.CHAT_ID ) CHAT_CREATEAT
                          from KAKAO_CHATS E
                          where E.TYPE in (1, 2)
                            and E.CREATEAT >= (select NVL(B.CREATEAT, sysdate)
                                               from KAKAO_READ_USERS B
                                               where B.EMAIL = ?
                                                 and B.ROOM_ID = E.ROOM_ID)
                          group by E.ROOM_ID) G on C.ROOM_ID = G.ROOM_ID
         left outer join kakao_join_users D on C.ROOM_ID = D.ROOM_ID
         left outer join KAKAO_READ_USERS G on G.ROOM_ID = D.ROOM_ID and G.EMAIL = D.EMAIL
         left outer join CUTOFF_RS E on D.EMAIL = E.TO_ID
         join KAKAO_USERS F on D.EMAIl = F.EMAIL
where B.EMAIL = ?
  and C.ROOM_ID = ?
  and B.STATUS = 1;

select *
from KAKAO_JOIN_USERS A
         JOIN KAKAO_ROOMS B ON A.ROOM_ID = B.ROOM_ID
         LEFT OUTER JOIN KAKAO_JOIN_USERS C =
on A.ROOM_ID = C.ROOM_ID
    LEFT oUTER JOIN


select A.ROOM_ID                                       as ROOM_ID,
       '[' || LISTAGG('{' || ' "id" : "' || F.ID || '",' || ' "name" : "' ||
                      nvl(DECODE(NVL(E.CUTOFF_RS, 1), 1, E.nickname, null), F.NAME) || '",' || ' "email" : "' ||
                      D.EMAIL || '",' || ' "message" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.MESSAGE, null) || '",' ||
                      ' "provider" : "' || F.PROVIDER || '",' || ' "lastReadChat" : "' || G.CHAT_ID || '",' ||
                      ' "profileImageUrl" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.profile_image_url, null) || '",' ||
                      ' "roomStatus" : "' || NVL(D.status, 0) || '",' || ' "friendStatus" : "' || NVL(E.status, 0) ||
                      '"' || '}',
                      ', ') within group ( order by E.nickname, F.NAME) ||
       ']'                                             as USERS,
       A.TYPE                                          as ROOM_TYPE,
       sum(case when B.STATUS = '1' then 1 else 0 end) as JOIN_USER_CNT,
       ''                                              as CHAT_CONTENT,
       ''                                              AS CHAT_TYPE,
       ''                                              AS CHAT_STATUS,
       ''                                              as CHAT_CREATEAT,
       ''                                              as ROOM_CREATEAT,
       (select count(*)
        from kakao_chats G
        where G.room_id = C.room_Id
          and G.CHAT_ID > (select chat_id
                           from KAKAO_READ_USERS
                           where room_id = G.room_id
                             and EMAIL = ?
                             and status in (1, 2)))    as UNREAD_CNT
from KAKAO_ROOMS A
         left outer join KAKAO_JOIN_USERS B ON A.ROOM_ID = B.ROOM_ID
         left outer join KAKAO_READ_USERS C on A.ROOM_ID = C.ROOM_ID
WHERE B.EMAIL = 'y2010212@naver.com'
  AND A.TYPE = 0
  AND A.STATUS = 1
group by A.ROOM_ID, A.TYPE;


select B.ROOM_ID,
       '[' || LISTAGG('{' || ' "id" : "' || E.ID || '",'
                          || ' "name" : "' || E.NAME || '",'
                          || ' "email" : "' || E.EMAIL || '",'
                          || ' "message" : "' || E.MESSAGE || '",'
                          || ' "provider" : "' || E.PROVIDER || '",'
                          || ' "lastReadChat" : "' || G.CHAT_ID || '",'
                          || ' "profileImageUrl" : "' || DECODE(NVL(E.CUTOFF_RS, 1), 1, F.profile_image_url, null) ||
                      '",'
                          || ' "roomStatus" : "' || NVL(D.status, 0) || '",'
                          || ' "friendStatus" : "' || NVL(E.status, 0) ||
                      '"' || '}',
                      from KAKAO_JOIN_USERS A
                      join KAKAO_ROOMS B on A.ROOM_ID = B.ROOM_ID
                      left outer join KAKAO_JOIN_USERS C on B.ROOM_ID = C.ROOM_ID
                      left outer join KAKAO_READ_USERS D on D.ROOM_ID = C.ROOM_ID
                      join KAKAO_USERS E on E.email = D.email
                      where A.EMAIL = 'y2010212@naver.com'
                          and B.TYPE = 1
                          and B.STATUS = 1
                      group by B.ROOM_ID,
                      B.NAME,
                      B.TYPE,
                      B.CREATEAT;


select A.ROOM_ID       as ROOM_ID,
       A.ROOM_ID       as ROOM_NAME,
       A.TYPE          as ROOM_TYPE,
       A.CREATEAT      as ROOM_CREATE_AT,
       C.CHAT_CONTENT  as CHAT_CONTENT,
       C.CHAT_TYPE     as CHAT_TYPE,
       C.CHAT_STATUS   as CHAT_STATUS,
       1               as JOIN_USER_CNT,
       C.CHAT_CREATEAT as CHAT_CREATE_AT
from KAKAO_ROOMS A
         join KAKAO_JOIN_USERS B on A.ROOM_ID = B.ROOM_ID
         join (select E.ROOM_ID,
                      max(E.CONTENT) keep (
                          DENSE_RANK last
                          order by
                              E.CREATEAT,
                              E.CHAT_ID
                          ) CHAT_CONTENT,
                      max(E.type) keep (
                          DENSE_RANK last
                          order by
                              E.CREATEAT,
                              E.CHAT_ID
                          ) CHAT_TYPE,
                      max(E.STATUS) keep (
                          DENSE_RANK last
                          order by
                              E.CREATEAT,
                              E.CHAT_ID
                          ) CHAT_STATUS,
                      max(E.CREATEAT) keep (
                          DENSE_RANK last
                          order by
                              E.CREATEAT,
                              E.CHAT_ID
                          ) CHAT_CREATEAT
               from KAKAO_CHATS E
               where E.TYPE in (1, 2)
               group by E.ROOM_ID) C on A.ROOM_ID = C.ROOM_ID
where A.TYPE = 0
  and A.STATUS = 1
  and B.EMAIL = 'y2010212@naver.com';

(select E.ROOM_ID,
        max(E.CONTENT) keep (
            DENSE_RANK last
            order by
                E.CREATEAT,
                E.CHAT_ID
            ) CHAT_CONTENT,
        max(E.type) keep (
            DENSE_RANK last
            order by
                E.CREATEAT,
                E.CHAT_ID
            ) CHAT_TYPE,
        max(E.STATUS) keep (
            DENSE_RANK last
            order by
                E.CREATEAT,
                E.CHAT_ID
            ) CHAT_STATUS,
        max(E.CREATEAT) keep (
            DENSE_RANK last
            order by
                E.CREATEAT,
                E.CHAT_ID
            ) CHAT_CREATEAT
 from KAKAO_CHATS E
 where E.TYPE in (1, 2)
 group by E.ROOM_ID);