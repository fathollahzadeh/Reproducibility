
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score > 0
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    ua.UserId,
    ua.PostsCount,
    ua.TotalBounty,
    CASE 
        WHEN r.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostType,
    CASE 
        WHEN ua.PostsCount IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS UserStatus,
    COALESCE(
        (SELECT STRING_AGG(CONCAT(b.Name, ' - ', CAST(b.Class AS TEXT)), ', ')
         FROM Badges b 
         WHERE b.UserId = ua.UserId), 
         'No Badges'
    ) AS UserBadges
FROM 
    RankedPosts r
JOIN 
    UserActivity ua ON r.PostId = ua.UserId
LEFT JOIN 
    Users u ON r.PostId = u.Id
WHERE 
    r.Rank <= 10
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC;
