WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes v
    GROUP BY v.PostId
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        (
            SELECT c.Text 
            FROM Comments c 
            WHERE c.PostId = ph.PostId 
            ORDER BY c.CreationDate DESC 
            LIMIT 1
        ) AS LastComment
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(cp.CloseReason, 'No Close Reason') AS CloseReason,
    COALESCE(cp.LastComment, 'No Comments') AS LastComment
FROM RankedPosts rp
LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.Rank <= 5
ORDER BY rp.CreationDate DESC;