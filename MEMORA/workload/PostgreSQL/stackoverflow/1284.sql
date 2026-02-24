WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(pb.TotalPosts, 0) AS TotalPosts,
        COALESCE(pb.Questions, 0) AS Questions,
        COALESCE(pb.Answers, 0) AS Answers,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostStats pb ON u.Id = pb.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
RankedUsers AS (
    SELECT 
        ue.*,
        RANK() OVER (ORDER BY ue.Reputation DESC, ue.TotalPosts DESC) AS UserRank
    FROM UserEngagement ue
)
SELECT 
    ru.UserId,
    ru.Reputation,
    ru.TotalPosts,
    ru.Questions,
    ru.Answers,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.UserRank
FROM RankedUsers ru
WHERE ru.UserRank <= 10
ORDER BY ru.UserRank;
