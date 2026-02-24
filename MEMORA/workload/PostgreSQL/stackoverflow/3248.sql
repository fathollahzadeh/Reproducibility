
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounties,
        DENSE_RANK() OVER (ORDER BY SUM(b.Class) DESC) AS BadgeRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(ua.DisplayName, 'Unknown User') AS TopUser,
    ua.TotalBadges,
    ua.TotalBounties
FROM 
    RankedPosts rp
FULL OUTER JOIN 
    UserActivity ua ON rp.Rank = 1 
WHERE 
    (rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) OR ua.TotalBadges IS NOT NULL)
    AND (rp.Score IS NOT NULL OR ua.TotalBounties IS NOT NULL)
ORDER BY 
    rp.Score DESC, ua.TotalBadges DESC;
