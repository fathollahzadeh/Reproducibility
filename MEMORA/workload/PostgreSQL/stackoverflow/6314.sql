
WITH UserScores AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 

PostMetrics AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.CommentCount, 
        P.AnswerCount, 
        U.Id AS UserId,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UserScores PS ON U.Id = PS.UserId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)

SELECT 
    US.UserId, 
    US.DisplayName, 
    US.Reputation, 
    P.PostId, 
    P.Title, 
    P.ViewCount, 
    P.CommentCount, 
    P.AnswerCount,
    US.Upvotes,
    US.Downvotes,
    US.BadgeCount
FROM 
    UserScores US
JOIN 
    PostMetrics P ON US.UserId = P.UserId
ORDER BY 
    US.Reputation DESC, 
    P.ViewCount DESC
LIMIT 10;
