WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankScore = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts) AND 
        rp.CommentCount > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.UserReputation,
    cp.FirstCloseDate,
    fp.PostCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    ClosedPosts cp ON fp.Id = cp.PostId
ORDER BY 
    fp.Score DESC NULLS LAST
LIMIT 50;