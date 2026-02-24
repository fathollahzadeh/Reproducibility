
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN C.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') THEN 1 END) AS RecentComments,
        COUNT(CASE WHEN V.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') THEN 1 END) AS RecentVotes
    FROM 
        Users U
        LEFT JOIN Comments C ON U.Id = C.UserId
        LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(PS.AverageScore, 0) AS AverageScore,
    COALESCE(RA.RecentComments, 0) AS RecentComments,
    COALESCE(RA.RecentVotes, 0) AS RecentVotes
FROM 
    Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN RecentActivity RA ON U.Id = RA.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.DisplayName;
