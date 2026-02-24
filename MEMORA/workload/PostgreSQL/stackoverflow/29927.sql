
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 60) AS AvgActiveDuration
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalWikis,
        AcceptedAnswers, 
        AvgActiveDuration,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts
    FROM 
        UserPostStats
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalStats AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.TotalPosts,
        t.TotalQuestions,
        t.TotalAnswers,
        t.TotalWikis,
        t.AcceptedAnswers,
        t.AvgActiveDuration,
        COALESCE(b.BadgeCount, 0) AS TotalBadges,
        COALESCE(b.GoldBadges, 0) AS TotalGoldBadges,
        COALESCE(b.SilverBadges, 0) AS TotalSilverBadges,
        COALESCE(b.BronzeBadges, 0) AS TotalBronzeBadges
    FROM 
        TopContributors t
    LEFT JOIN 
        UserBadges b ON t.UserId = b.UserId
    WHERE 
        t.RankByPosts <= 10
)
SELECT 
    f.DisplayName,
    f.TotalPosts,
    f.TotalQuestions,
    f.TotalAnswers,
    f.TotalWikis,
    f.AcceptedAnswers,
    f.AvgActiveDuration,
    f.TotalBadges,
    f.TotalGoldBadges,
    f.TotalSilverBadges,
    f.TotalBronzeBadges
FROM 
    FinalStats f
ORDER BY 
    f.TotalPosts DESC;
