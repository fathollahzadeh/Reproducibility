
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0) AS AverageBounty,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score,
        rp.AverageBounty,
        rp.CommentCount,
        rp.HighestBadgeClass
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 AND 
        rp.Score > 10 AND 
        rp.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
)
SELECT 
    fp.*,
    COALESCE(pt.Name, 'No Type') AS PostType
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostTypes pt ON EXISTS (SELECT 1 FROM Posts WHERE Id = fp.PostId AND PostTypeId = pt.Id)
ORDER BY 
    fp.Score DESC
LIMIT 50;
