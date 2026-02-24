
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
RankedPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score > 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RecentPosts rp
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(rp.TotalBounty, 0) AS TotalBounty,
    rp.ScoreCategory
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1 
    AND rp.CommentCount > 5
ORDER BY 
    COALESCE(rp.TotalBounty, 0) DESC, rp.CreationDate DESC;
