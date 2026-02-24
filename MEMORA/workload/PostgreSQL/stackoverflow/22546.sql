
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    AND p.Score > 0
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS DeletedDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
),

TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN phd.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
        SUM(CASE WHEN phd.ReopenedDate IS NOT NULL THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
    GROUP BY t.TagName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    phd.ClosedDate,
    phd.ReopenedDate,
    phd.DeletedDate,
    ts.TagName,
    ts.PostCount,
    ts.ClosedPosts,
    ts.ReopenedPosts
FROM RankedPosts rp
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN TagStats ts ON ts.PostCount > 5
WHERE rp.RankScore <= 10 
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
