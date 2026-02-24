WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score >= 0 THEN 1 ELSE 0 END) AS NonNegativeScorePosts,
        SUM(V.BountyAmount) AS TotalBounty 
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY U.Id, U.DisplayName, U.Reputation
), UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
), CombinedUserStats AS (
    SELECT 
        US.UserId, 
        US.DisplayName, 
        US.Reputation, 
        US.TotalPosts, 
        US.TotalQuestions, 
        US.TotalAnswers, 
        US.NonNegativeScorePosts,
        US.TotalBounty,
        UB.GoldBadges, 
        UB.SilverBadges, 
        UB.BronzeBadges
    FROM UserStatistics US
    LEFT JOIN UserBadges UB ON US.UserId = UB.UserId
)
SELECT 
    CUS.UserId, 
    CUS.DisplayName, 
    CUS.Reputation, 
    CUS.TotalPosts, 
    CUS.TotalQuestions, 
    CUS.TotalAnswers,
    CUS.NonNegativeScorePosts,
    CUS.TotalBounty,
    COALESCE(CUS.GoldBadges, 0) AS GoldBadges,
    COALESCE(CUS.SilverBadges, 0) AS SilverBadges,
    COALESCE(CUS.BronzeBadges, 0) AS BronzeBadges
FROM CombinedUserStats CUS
WHERE CUS.Reputation > 1000 
ORDER BY CUS.TotalPosts DESC, CUS.Reputation DESC
LIMIT 10;