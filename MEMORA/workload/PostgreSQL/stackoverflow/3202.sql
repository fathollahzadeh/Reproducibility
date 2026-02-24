
WITH UserVotes AS (
    SELECT 
        UserId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(v.Upvotes, 0) AS TotalUpvotes,
        COALESCE(v.Downvotes, 0) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        UserVotes v ON p.OwnerUserId = v.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    cl.CloseReasons,
    cl.CloseCount
FROM 
    PostStats ps
LEFT JOIN 
    ClosedPosts cl ON ps.PostId = cl.PostId
WHERE 
    ps.RecentPostRank <= 5
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
