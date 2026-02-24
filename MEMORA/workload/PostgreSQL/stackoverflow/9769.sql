WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore,
        AVG(COALESCE(NULLIF(p.ViewCount, 0), 1)) AS AvgViewCount,
        SUM(COALESCE(NULLIF(c.Id, 0), 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.Questions,
        ua.Answers,
        ua.TotalQuestionScore,
        ua.TotalAnswerScore,
        ua.AvgViewCount,
        ua.TotalComments,
        COALESCE(bc.TotalBadges, 0) AS TotalBadges,
        COALESCE(bc.GoldBadges, 0) AS GoldBadges,
        COALESCE(bc.SilverBadges, 0) AS SilverBadges,
        COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserActivity ua
    LEFT JOIN 
        BadgeCounts bc ON ua.UserId = bc.UserId
)
SELECT 
    cs.DisplayName,
    cs.TotalPosts,
    cs.Questions,
    cs.Answers,
    cs.TotalQuestionScore,
    cs.TotalAnswerScore,
    cs.AvgViewCount,
    cs.TotalComments,
    cs.TotalBadges,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges
FROM 
    CombinedStats cs
WHERE 
    cs.TotalPosts > 10
ORDER BY 
    cs.TotalQuestionScore DESC, cs.TotalPosts DESC
LIMIT 100;
