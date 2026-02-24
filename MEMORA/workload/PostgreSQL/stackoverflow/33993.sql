WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date > cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.UpVotes, 0) AS UpVotes,
    COALESCE(ub.DownVotes, 0) AS DownVotes,
    rb.BadgeNames,
    ph.PostId,
    ph.Title,
    ph.Level,
    p.CreationDate,
    p.ViewCount,
    p.Score
FROM 
    Users u
LEFT JOIN 
    UserVoteCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON p.Id = ph.PostId
WHERE 
    (ub.UpVotes - ub.DownVotes) > 10 
    AND (p.Score > 5 OR p.ViewCount > 100)
ORDER BY 
    p.CreationDate DESC,
    ph.Level ASC;