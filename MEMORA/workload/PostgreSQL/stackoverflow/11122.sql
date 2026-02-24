
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Posts A WHERE A.ParentId = P.Id) AS AnswerCount,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.CommentCount,
    PS.VoteCount,
    PS.AnswerCount,
    US.UserId,
    US.DisplayName,
    US.BadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON PS.OwnerUserId = U.Id
JOIN 
    UserStats US ON US.UserId = U.Id
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;
