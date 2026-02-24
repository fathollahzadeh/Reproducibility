
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        MIN(ph.CreationDate) AS FirstChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(SUM(CASE WHEN pd.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN pd.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount,
        MAX(pd.FirstChangeDate) AS LastChangeDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryData pd ON rp.PostId = pd.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CloseCount,
    ps.ReopenCount,
    CASE 
        WHEN ps.CloseCount > ps.ReopenCount THEN 'More Closed'
        WHEN ps.ReopenCount > ps.CloseCount THEN 'More Reopened'
        ELSE 'Equal'
    END AS ClosureStatus,
    (CASE 
        WHEN ps.ViewCount IS NULL THEN 'No Views Yet' 
        ELSE CONCAT('Views: ', CAST(ps.ViewCount AS VARCHAR)) 
    END) AS ViewStatus,
    DENSE_RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 0
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC NULLS LAST
LIMIT 10
OFFSET 0;
