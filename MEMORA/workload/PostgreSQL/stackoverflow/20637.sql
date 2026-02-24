WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        LEAD(p.CreationDate) OVER (ORDER BY p.CreationDate) AS NextPostDate
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        c.PostId AS CommentedPostId,
        COUNT(c.Id) AS TotalComments,
        MIN(c.CreationDate) AS FirstCommentDate,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        MIN(ph.Comment) AS CloseReason
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.UserId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rc.TotalComments,
    rc.FirstCommentDate,
    rc.LastCommentDate,
    cp.CloseReason,
    CASE 
        WHEN rp.NextPostDate IS NULL THEN 'No following posts'
        WHEN rp.NextPostDate < cast('2024-10-01 12:34:56' as timestamp) THEN 'Post followed by another'
        ELSE 'Post is last in the timeline'
    END AS PostStatus,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'Data not available'
        ELSE (rp.ViewCount / NULLIF(rp.CommentCount, 0))::text || ' views per comment'
    END AS ViewsPerComment
FROM RankedPosts rp
LEFT JOIN RecentComments rc ON rp.PostId = rc.CommentedPostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.Rank <= 5
ORDER BY rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;