
WITH RecursiveUserAccolades AS (
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
PostsWithRank AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.PostId) AS TotalPosts,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        PostsWithRank p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsersWithPosts AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalScore,
        ups.AvgScore,
        ra.BadgeCount,
        ra.GoldBadges,
        ra.SilverBadges,
        ra.BronzeBadges
    FROM 
        UserPostStats ups
    JOIN 
        RecursiveUserAccolades ra ON ups.UserId = ra.UserId
    WHERE 
        ups.TotalPosts > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalBenchmark AS (
    SELECT 
        t.UserId,
        t.DisplayName,
        t.TotalPosts,
        t.TotalScore,
        t.AvgScore,
        t.BadgeCount,
        t.GoldBadges,
        t.SilverBadges,
        t.BronzeBadges,
        ua.CommentCount,
        ua.TotalBounty
    FROM 
        TopUsersWithPosts t
    JOIN 
        UserActivity ua ON t.UserId = ua.UserId
)
SELECT 
    fb.DisplayName,
    fb.TotalPosts,
    fb.TotalScore,
    fb.AvgScore,
    fb.BadgeCount,
    fb.GoldBadges,
    fb.SilverBadges,
    fb.BronzeBadges,
    fb.CommentCount,
    fb.TotalBounty,
    CASE 
        WHEN fb.AvgScore > 20 THEN 'High Performer'
        WHEN fb.AvgScore BETWEEN 10 AND 20 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.TotalScore DESC
LIMIT 10;
