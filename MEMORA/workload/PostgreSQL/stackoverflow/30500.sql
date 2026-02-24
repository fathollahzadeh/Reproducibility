WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  
), PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        COALESCE(ps.VoteCount, 0) AS VoteCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadgeCount ub ON u.Id = ub.UserId
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    ra.LastActivityDate,
    ra.VoteCount,
    ra.BadgeCount,
    CASE 
        WHEN ra.VoteCount > 100 THEN 'Highly Active' 
        WHEN ra.VoteCount BETWEEN 50 AND 100 THEN 'Moderately Active' 
        ELSE 'Less Active' 
    END AS ActivityStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostHierarchy ph
LEFT JOIN 
    RecentActivity ra ON ph.PostId = ra.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = ph.PostId  
WHERE 
    ph.Level < 3  
GROUP BY 
    ph.PostId, ph.Title, ph.Level, ra.LastActivityDate, ra.VoteCount, ra.BadgeCount
ORDER BY 
    ra.LastActivityDate DESC, ra.VoteCount DESC
LIMIT 100;