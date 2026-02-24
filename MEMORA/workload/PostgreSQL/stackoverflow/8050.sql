
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeTotal
    FROM 
        Badges
    GROUP BY 
        UserId
),
EngagementSummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.TotalScore,
        UA.TotalUpvotes,
        UA.TotalDownvotes,
        COALESCE(BC.BadgeTotal, 0) AS BadgeTotal
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgeCount BC ON UA.UserId = BC.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalUpvotes,
    TotalDownvotes,
    BadgeTotal
FROM 
    EngagementSummary
ORDER BY 
    Reputation DESC, 
    TotalScore DESC, 
    PostCount DESC
LIMIT 100;
