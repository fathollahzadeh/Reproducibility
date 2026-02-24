
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        COALESCE(COUNT(ans.Id), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenVotes,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Posts ans ON p.Id = ans.ParentId
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.ViewCount, p.Score, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pm.*,
        RANK() OVER (ORDER BY pm.Score DESC, pm.AnswerCount DESC, pm.ViewCount DESC) AS PostRank
    FROM PostMetrics pm
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CloseVotes,
    rp.ReopenVotes,
    rp.OwnerDisplayName
FROM RankedPosts rp
WHERE rp.PostRank <= 100  
ORDER BY rp.PostRank;
