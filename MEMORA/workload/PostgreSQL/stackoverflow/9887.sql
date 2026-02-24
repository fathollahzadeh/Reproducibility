WITH UserRanks AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 END) AS TotalClosedPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(PS.TotalClosedPosts, 0) AS TotalClosedPosts,
    COALESCE(PS.TotalComments, 0) AS TotalComments,
    COALESCE(UB.TotalBadges, 0) AS TotalBadges,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
FROM UserRanks UR
LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN UserBadges UB ON UR.UserId = UB.UserId
ORDER BY UR.Reputation DESC, UR.DisplayName ASC
LIMIT 50;
