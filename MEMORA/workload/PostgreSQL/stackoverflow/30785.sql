WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(pa.TotalPosts, 0) AS TotalPosts,
        COALESCE(pa.Questions, 0) AS Questions,
        COALESCE(pa.Answers, 0) AS Answers,
        COALESCE(pa.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(pa.TotalScore, 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN 
        PostActivity pa ON u.Id = pa.OwnerUserId
),
RankedUsers AS (
    SELECT 
        us.*,
        RANK() OVER (ORDER BY us.TotalScore DESC, us.TotalPosts DESC) AS UserRank
    FROM 
        UserPostStats us
)
SELECT 
    ru.UserId,
    ru.GoldBadges,
    ru.SilverBadges,
    ru.BronzeBadges,
    ru.TotalPosts,
    ru.Questions,
    ru.Answers,
    ru.ClosedPosts,
    ru.TotalScore,
    ru.UserRank
FROM 
    RankedUsers ru
WHERE 
    ru.TotalPosts > 0 OR ru.TotalScore > 0
ORDER BY 
    ru.UserRank
LIMIT 10;