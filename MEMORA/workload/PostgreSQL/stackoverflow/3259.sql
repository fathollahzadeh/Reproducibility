WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsUsed
    FROM Posts P
    JOIN LATERAL (
        SELECT 
            unnest(string_to_array(P.Tags, '><')) AS TagName
    ) T ON TRUE
    WHERE P.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    COALESCE(RP.TotalPosts, 0) AS TotalPosts,
    COALESCE(RP.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(RP.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(RP.AverageScore, 0) AS AverageScore,
    COALESCE(RB.GoldBadges, 0) AS GoldBadges,
    COALESCE(RB.SilverBadges, 0) AS SilverBadges,
    COALESCE(RB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(RP.TagsUsed, 'No Tags') AS TagsUsed
FROM UserReputation UR
LEFT JOIN RecentPostStats RP ON UR.UserId = RP.OwnerUserId
LEFT JOIN UserBadges RB ON UR.UserId = RB.UserId
WHERE UR.ReputationRank <= 50
ORDER BY UR.Reputation DESC;