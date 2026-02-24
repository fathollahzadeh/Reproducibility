WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) FILTER (WHERE c.Id IS NOT NULL) OVER (PARTITION BY p.OwnerUserId) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND p.PostTypeId = 1  
),
TopScores AS (
    SELECT 
        rp.OwnerDisplayName,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViews,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5  
    GROUP BY 
        rp.OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    t.OwnerDisplayName,
    t.TotalScore,
    t.AverageViews,
    t.TotalComments,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    TopScores t
LEFT JOIN 
    UserBadges ub ON ub.UserId = (SELECT Id FROM Users WHERE DisplayName = t.OwnerDisplayName LIMIT 1)
ORDER BY 
    t.TotalScore DESC
LIMIT 10;