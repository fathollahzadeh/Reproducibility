WITH UserBadgeCounts AS (
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
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UA.PostCount, 0) AS PostCount,
        COALESCE(UA.QuestionCount, 0) AS QuestionCount,
        COALESCE(UA.AnswerCount, 0) AS AnswerCount,
        COALESCE(UA.CommentCount, 0) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        UserActivity UA ON U.Id = UA.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    BadgeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
FROM 
    UserPostStats
WHERE 
    Reputation > 1000
ORDER BY 
    ReputationRank, Reputation DESC;
