
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    cr.CloseCount,
    ur.DisplayName,
    ur.Reputation,
    ur.LastVoteDate
FROM 
    Posts p
JOIN 
    PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN 
    ClosedPosts cr ON p.Id = cr.PostId
LEFT JOIN 
    Users owner ON p.OwnerUserId = owner.Id
JOIN 
    UserReputation ur ON owner.Id = ur.UserId
WHERE 
    p.CreationDate > (DATE '2024-10-01' - INTERVAL '1 year')
    AND (cr.CloseCount IS NULL OR cr.CloseCount = 0)
ORDER BY 
    ps.CommentRank, ps.CommentCount DESC;
