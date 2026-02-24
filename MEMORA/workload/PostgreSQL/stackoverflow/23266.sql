
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
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        us.Id AS UserId, 
        us.DisplayName,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.QuestionsCount, 0) AS TotalQuestions,
        COALESCE(ps.AnswersCount, 0) AS TotalAnswers,
        COALESCE(bs.BadgeCount, 0) AS TotalBadges,
        COALESCE(bs.GoldBadges, 0) AS TotalGoldBadges,
        COALESCE(bs.SilverBadges, 0) AS TotalSilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS TotalBronzeBadges
    FROM 
        UserBadgeStats bs
    FULL OUTER JOIN 
        PostStats ps ON bs.UserId = ps.OwnerUserId
    FULL OUTER JOIN 
        Users us ON us.Id = COALESCE(bs.UserId, ps.OwnerUserId)
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecencyRank
    FROM 
        Posts p
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBadges,
    ua.TotalGoldBadges,
    ua.TotalSilverBadges,
    ua.TotalBronzeBadges,
    rpa.Title AS MostRecentPostTitle,
    rpa.CreationDate AS MostRecentPostDate
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPostActivity rpa ON ua.UserId = rpa.OwnerUserId AND rpa.RecencyRank = 1
WHERE 
    ua.TotalBadges >= 5
    OR (ua.TotalPosts = 0 AND ua.TotalQuestions > 2)
ORDER BY 
    ua.TotalBadges DESC, ua.TotalPosts DESC
LIMIT 100;
