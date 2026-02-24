WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PostStatistics AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViews
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
    GROUP BY 
        OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AvgViews,
    ub.BadgeCount
FROM 
    PostStatistics ps
JOIN 
    UserBadges ub ON ps.OwnerDisplayName = ub.DisplayName
ORDER BY 
    ps.TotalScore DESC, ub.BadgeCount DESC;
