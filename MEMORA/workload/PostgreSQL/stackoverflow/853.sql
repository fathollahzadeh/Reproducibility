
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        postId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY postId
),
ClosedPostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM Comments c
    JOIN Posts p ON c.PostId = p.Id
    WHERE p.ClosedDate IS NOT NULL
    GROUP BY c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(cpcs.CommentCount, 0) AS CommentCount,
    COALESCE(cpcs.CommentTexts, 'No comments') AS CommentTexts,
    CASE WHEN rp.Rank <= 5 THEN 'Top Posts' ELSE 'Other Posts' END AS PostCategory
FROM RankedPosts rp
LEFT JOIN PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN ClosedPostComments cpcs ON rp.PostId = cpcs.PostId
LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE ph.PostId IS NULL OR ph.CreationDate IS NULL
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
