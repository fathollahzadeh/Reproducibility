WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT crt.Name) AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id 
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.PostType,
        rp.Rank,
        rp.TotalBounty,
        rp.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.PostType,
    ps.Rank,
    ps.TotalBounty,
    ps.CommentCount,
    ps.CloseCount,
    ps.CloseReasons
FROM PostStatistics ps
WHERE ps.Rank <= 5 
    AND ps.TotalBounty > 0
    AND ps.CommentCount > 5
ORDER BY ps.PostType, ps.Score DESC;