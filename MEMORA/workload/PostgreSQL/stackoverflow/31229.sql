
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        ph.Level + 1,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(d.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVotes 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVotes 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 3 
        GROUP BY 
            PostId
    ) d ON p.Id = d.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Level,
        ph.Title,
        ph.CreationDate
    FROM 
        PostHierarchy ph
    INNER JOIN 
        PostHistory phist ON ph.PostId = phist.PostId
    WHERE 
        phist.PostHistoryTypeId = 10
),
RecentPosts AS (
    SELECT 
        ps.* 
    FROM 
        PostStats ps
    WHERE 
        ps.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)

SELECT 
    rp.Title,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    COALESCE(cp.Level, -1) AS ClosedLevel,
    CASE 
        WHEN COALESCE(cp.Level, -1) > -1 THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RecentPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
ORDER BY 
    rp.UpVotes DESC, 
    rp.CreationDate DESC;
