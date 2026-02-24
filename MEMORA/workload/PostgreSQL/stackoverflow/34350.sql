WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(v.upVotes, 0) AS UpVoteCount,
        COALESCE(v.downVotes, 0) AS DownVoteCount,
        (COALESCE(v.upVotes, 0) - COALESCE(v.downVotes, 0)) AS NetVoteCount
    FROM RankedPosts rp
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Count
        FROM Comments
        GROUP BY PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downVotes
        FROM Votes
        GROUP BY PostId
    ) v ON rp.PostId = v.PostId
    WHERE rp.rn = 1
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
FinalMetrics AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.LastActivityDate,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        pm.UpVoteCount,
        pm.DownVoteCount,
        pm.NetVoteCount,
        COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId = 10 THEN phs.HistoryCount END), 0) AS CloseHistoryCount,
        COALESCE(SUM(CASE WHEN phs.PostHistoryTypeId = 11 THEN phs.HistoryCount END), 0) AS ReopenHistoryCount
    FROM PostMetrics pm
    LEFT JOIN PostHistoryStats phs ON pm.PostId = phs.PostId
    GROUP BY pm.PostId, pm.Title, pm.LastActivityDate, pm.Score, pm.ViewCount, pm.CommentCount, pm.UpVoteCount, pm.DownVoteCount, pm.NetVoteCount
)
SELECT 
    p.PostId,
    p.Title,
    p.LastActivityDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.DownVoteCount,
    p.NetVoteCount,
    p.CloseHistoryCount,
    p.ReopenHistoryCount,
    CASE 
        WHEN p.ReopenHistoryCount > 0 THEN 'Post has been reopened'
        WHEN p.CloseHistoryCount > 0 THEN 'Post has been closed'
        ELSE 'Post status normal'
    END AS PostStatus
FROM FinalMetrics p
ORDER BY p.LastActivityDate DESC
LIMIT 100;