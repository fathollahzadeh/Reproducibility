
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 END) AS TotalQuestions,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 END) AS TotalAnswers,
        SUM(CASE 
            WHEN p.Score > 0 THEN 1 
            ELSE 0 END) AS TotalUpvotedPosts,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TagPostStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 END) AS TotalQuestions,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 END) AS TotalAnswers
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[])
    GROUP BY t.Id, t.TagName
),
UserBadgesStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    COALESCE(u.TotalPosts, 0) AS TotalPosts,
    COALESCE(u.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(u.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(u.TotalUpvotedPosts, 0) AS TotalUpvotedPosts,
    COALESCE(u.AverageScore, 0) AS AverageScore,
    u.LastPostDate,
    COALESCE(b.TotalBadges, 0) AS TotalBadges,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges
FROM UserPostStats u
LEFT JOIN UserBadgesStats b ON u.UserId = b.UserId
ORDER BY u.TotalPosts DESC
LIMIT 10;
