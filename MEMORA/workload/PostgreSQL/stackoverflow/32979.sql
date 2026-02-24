
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.OwnerUserId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentPostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate > CURRENT_DATE - INTERVAL '30 DAY'
    GROUP BY 
        c.PostId
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.OwnerUserId,
    u.DisplayName AS OwnerDisplayName,
    ph.Level,
    COALESCE(pvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(rpc.CommentCount, 0) AS RecentCommentCount,
    COALESCE(cr.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteSummary pvs ON p.Id = pvs.PostId
LEFT JOIN 
    RecentPostComments rpc ON p.Id = rpc.PostId
LEFT JOIN 
    PostCloseReasons cr ON p.Id = cr.PostId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
ORDER BY 
    TotalUpVotes DESC, RecentCommentCount DESC;
