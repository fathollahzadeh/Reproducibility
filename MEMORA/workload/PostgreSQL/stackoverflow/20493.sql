
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), UserRankings AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ROW_NUMBER() OVER (ORDER BY ua.PostCount DESC) AS UserRank,
        RANK() OVER (ORDER BY ua.BadgeCount DESC) AS BadgeRank,
        CASE 
            WHEN ua.PostCount = 0 THEN NULL 
            ELSE ROUND((ua.PositivePosts * 1.0 / NULLIF(ua.PostCount, 0)) * 100, 2) 
        END AS PositivePostPercentage
    FROM 
        UserActivity ua
), RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 
        END AS HasAcceptedAnswer,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
), UserPostStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(rp.Id) AS RecentPostCount,
        SUM(rp.ViewCount) AS TotalRecentViews,
        AVG(rp.ViewCount) AS AvgViewCount,
        SUM(rp.HasAcceptedAnswer) AS TotalAcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        RecentPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ur.UserRank,
    ur.DisplayName,
    ur.BadgeRank,
    ur.PositivePostPercentage,
    ups.RecentPostCount,
    ups.TotalRecentViews,
    ups.AvgViewCount,
    ups.TotalAcceptedAnswers
FROM 
    UserRankings ur
LEFT JOIN 
    UserPostStatistics ups ON ur.DisplayName = ups.DisplayName
WHERE 
    ur.UserRank <= 10
ORDER BY 
    ur.UserRank;
