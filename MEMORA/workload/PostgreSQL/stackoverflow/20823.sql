WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Anonymous') AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Owner,
        CASE 
            WHEN rp.OwnerPostRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Owner, rp.OwnerPostRank
),
MaxViews AS (
    SELECT 
        MAX(ViewCount) AS MaxViewCount
    FROM 
        PostStats
),
BountyDetails AS (
    SELECT 
        ps.PostId,
        ps.TotalBounty,
        CASE 
            WHEN ps.TotalBounty IS NULL THEN 'No Bounty'
            WHEN ps.TotalBounty > 50 THEN 'High Bounty'
            ELSE 'Low Bounty'
        END AS BountyLevel
    FROM 
        PostStats ps
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Owner,
    ps.PostCategory,
    ps.CommentCount,
    bd.TotalBounty,
    bd.BountyLevel,
    (SELECT 'Top Viewed' 
     FROM MaxViews mv 
     WHERE ps.ViewCount = mv.MaxViewCount) AS IsTopViewed
FROM 
    PostStats ps
LEFT JOIN 
    BountyDetails bd ON ps.PostId = bd.PostId
WHERE 
    (ps.ViewCount > (SELECT AVG(ViewCount) FROM PostStats) OR bd.TotalBounty IS NOT NULL)
ORDER BY 
    ps.ViewCount DESC, ps.CommentCount DESC
LIMIT 100;