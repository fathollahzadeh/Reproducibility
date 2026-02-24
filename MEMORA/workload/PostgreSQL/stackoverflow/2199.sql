
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBountyAmount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.AvgBountyAmount,
        rp.CommentCount
    FROM 
        RecentPosts rp
    WHERE 
        rp.CommentCount > 10 AND
        rp.AvgBountyAmount > 50
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.OwnerDisplayName,
    fp.AvgBountyAmount,
    fp.CommentCount
FROM 
    FilteredPosts fp
WHERE 
    fp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    fp.Score DESC;
