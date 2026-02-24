WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        1 AS Level,
        p.ParentId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.Score,
        a.AnswerCount,
        ph.Level + 1,
        a.ParentId
    FROM 
        Posts a
    INNER JOIN 
        PostHierarchy ph ON a.ParentId = ph.Id
    WHERE 
        a.PostTypeId = 2  
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
    GROUP BY 
        v.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    ph.Level,
    p.CreationDate,
    p.Score,
    u.Reputation,
    ub.BadgeCount,
    ub.BadgeNames,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes
FROM 
    Posts p
JOIN 
    PostHierarchy ph ON p.Id = ph.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    AND (p.Score > 5 OR ph.Level = 1)  
ORDER BY 
    ph.Level, 
    p.Score DESC,
    RecentUpVotes DESC
LIMIT 100;