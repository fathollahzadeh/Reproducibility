
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), PostEngagement AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    COALESCE(BC.BadgeCount, 0) AS BadgeCount,
    COALESCE(PE.CommentCount, 0) AS CommentCount,
    COALESCE(PE.UpvoteCount, 0) AS UpvoteCount,
    COALESCE(PE.DownvoteCount, 0) AS DownvoteCount,
    UR.PostCount,
    UR.QuestionCount,
    UR.AnswerCount
FROM 
    UserReputation UR
LEFT JOIN 
    BadgeCounts BC ON UR.UserId = BC.UserId
LEFT JOIN 
    PostEngagement PE ON UR.UserId = PE.OwnerUserId
ORDER BY 
    UR.Reputation DESC, 
    UR.PostCount DESC,
    UR.UserId;
