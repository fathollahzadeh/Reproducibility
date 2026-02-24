WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
HighReputationUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Views, 
        PostCount, 
        AnswerCount, 
        AcceptedAnswers, 
        BadgeCount
    FROM 
        UserStats
    WHERE 
        Reputation > (SELECT AVG(Reputation) FROM Users)
),
UserPerformance AS (
    SELECT 
        H.DisplayName,
        H.Reputation,
        H.PostCount,
        H.AnswerCount,
        H.AcceptedAnswers,
        H.BadgeCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.UserId = H.UserId), 0) AS TotalVotes,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.UserId = H.UserId), 0) AS TotalComments
    FROM 
        HighReputationUsers H
)
SELECT 
    U.*,
    (TotalVotes + TotalComments) AS EngagementScore
FROM 
    UserPerformance U
ORDER BY 
    EngagementScore DESC
LIMIT 10;
