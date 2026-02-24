WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
RankedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        pc.TotalPosts,
        pc.QuestionsCount,
        pc.AnswersCount,
        ub.TotalBadges,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ur.ReputationRank
    FROM UserReputation ur
    LEFT JOIN PostCounts pc ON ur.UserId = pc.OwnerUserId
    LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    COALESCE(ru.TotalPosts, 0) AS TotalPosts,
    COALESCE(ru.QuestionsCount, 0) AS QuestionsCount,
    COALESCE(ru.AnswersCount, 0) AS AnswersCount,
    COALESCE(ru.TotalBadges, 0) AS TotalBadges,
    COALESCE(ru.GoldBadges, 0) AS GoldBadges,
    COALESCE(ru.SilverBadges, 0) AS SilverBadges,
    COALESCE(ru.BronzeBadges, 0) AS BronzeBadges,
    RANK() OVER (ORDER BY ru.Reputation DESC, ru.TotalPosts DESC) AS OverallRank,
    ARRAY_AGG(DISTINCT p.Title) FILTER (WHERE p.OwnerUserId IS NOT NULL) AS TopPosts
FROM RankedUsers ru
LEFT JOIN Posts p ON ru.UserId = p.OwnerUserId
GROUP BY ru.UserId, ru.DisplayName, ru.Reputation, ru.TotalPosts, ru.QuestionsCount, ru.AnswersCount, ru.TotalBadges, ru.GoldBadges, ru.SilverBadges, ru.BronzeBadges
HAVING COALESCE(ru.TotalPosts, 0) > 5
ORDER BY OverallRank, ru.DisplayName
LIMIT 10;
