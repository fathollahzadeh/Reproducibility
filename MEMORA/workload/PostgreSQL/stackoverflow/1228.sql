
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        rp.CommentCount,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM RankedPosts rp
    WHERE rp.RankScore <= 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT chr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes chr ON CAST(ph.Comment AS INTEGER) = chr.Id
    WHERE ph.PostHistoryTypeId = 10 
    GROUP BY ph.PostId
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    pp.NetVotes,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'No reasons') AS CloseReasons
FROM PopularPosts pp
LEFT JOIN ClosedPosts cp ON pp.PostId = cp.PostId
ORDER BY pp.NetVotes DESC, pp.Score DESC;
