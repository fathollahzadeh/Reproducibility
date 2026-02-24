
WITH UserPostActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 0 
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.UpVotes,
    U.DownVotes,
    U.BadgeCount,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.CommentCount,
    P.VoteCount
FROM 
    UserPostActivity U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.PostCount DESC, U.UpVotes DESC, P.VoteCount DESC;
