WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        p.LastActivityDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopUserPosts AS (
    SELECT 
        up.OwnerUserId,
        COUNT(up.PostId) AS TotalPosts,
        SUM(up.Score) AS TotalScore,
        AVG(up.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts up
    WHERE 
        up.RankByScore <= 5 
    GROUP BY 
        up.OwnerUserId
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    up.TotalPosts,
    up.TotalScore,
    up.AvgViewCount,
    ub.BadgeCount
FROM 
    Users u
JOIN 
    TopUserPosts up ON u.Id = up.OwnerUserId
JOIN 
    UsersWithBadges ub ON u.Id = ub.UserId
WHERE 
    ub.BadgeCount > 0 
ORDER BY 
    up.TotalScore DESC,
    up.TotalPosts DESC;