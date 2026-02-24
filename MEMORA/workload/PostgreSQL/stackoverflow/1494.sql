
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostWithTopVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UserReputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        RankedPosts rp
        LEFT JOIN Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount, rp.UserReputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReason
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UserReputation,
    p.UpVoteCount,
    p.DownVoteCount,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReasonStatus
FROM 
    PostWithTopVotes p
    LEFT JOIN ClosedPosts cp ON p.PostId = cp.PostId
WHERE 
    p.UserReputation > 1000
    AND (p.UpVoteCount - p.DownVoteCount) > 5
ORDER BY 
    p.Score DESC, 
    p.CommentCount DESC
LIMIT 50;
