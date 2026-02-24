WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        SUM(COALESCE(v.VoteTypeId, 0)) OVER (PARTITION BY p.Id) AS TotalVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.TotalVotes,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.RankByDate <= 10 
),
PostRanking AS (
    SELECT 
        fp.*,
        CASE
            WHEN TotalVotes > 50 THEN 'Highly Engaged'
            WHEN TotalVotes BETWEEN 21 AND 50 THEN 'Moderately Engaged'
            ELSE 'Low Engagement'
        END AS EngagementCategory
    FROM FilteredPosts fp
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (1, 4, 5) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS ClosureStatus
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.ViewCount,
    pr.CommentCount,
    pr.TotalVotes,
    phs.LastEdited,
    phs.EditCount,
    phs.TitleEdits,
    phs.ClosureStatus,
    pr.EngagementCategory
FROM PostRanking pr
LEFT JOIN PostHistorySummary phs ON pr.PostId = phs.PostId
WHERE 
    phs.EditCount > 5
    OR phs.ClosureStatus > 0
ORDER BY 
    pr.ViewCount DESC, 
    pr.TotalVotes DESC
LIMIT 100;