
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        ubs.UserId,
        ubs.DisplayName,
        ubs.BadgeCount,
        ubs.GoldBadges,
        ubs.SilverBadges,
        ubs.BronzeBadges,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        ps.Wikis,
        ps.TotalScore,
        ps.AvgViews
    FROM 
        UserBadgeStats ubs
    LEFT JOIN 
        PostStats ps ON ubs.UserId = ps.OwnerUserId
)
SELECT 
    c.DisplayName,
    COALESCE(c.BadgeCount, 0) AS BadgeCount,
    COALESCE(c.GoldBadges, 0) AS GoldBadges,
    COALESCE(c.SilverBadges, 0) AS SilverBadges,
    COALESCE(c.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(c.TotalPosts, 0) AS TotalPosts,
    COALESCE(c.Questions, 0) AS Questions,
    COALESCE(c.Answers, 0) AS Answers,
    COALESCE(c.Wikis, 0) AS Wikis,
    COALESCE(c.TotalScore, 0) AS TotalScore,
    COALESCE(c.AvgViews, 0) AS AvgViews
FROM 
    CombinedStats c
ORDER BY 
    c.TotalScore DESC, 
    c.BadgeCount DESC
LIMIT 10;
