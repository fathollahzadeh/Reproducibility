
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.ParentId, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
QuestionStats AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Level,
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        tb.BadgeNames
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    JOIN 
        UserStats us ON p.OwnerUserId = us.UserId
    LEFT JOIN 
        TopBadges tb ON us.UserId = tb.UserId
    WHERE 
        p.PostTypeId = 1 
)
SELECT 
    qs.Title,
    qs.DisplayName,
    qs.Reputation,
    qs.UpVotes,
    qs.DownVotes,
    qs.BadgeNames,
    qs.Level,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
FROM 
    QuestionStats qs
LEFT JOIN 
    Comments c ON c.PostId = qs.Id
LEFT JOIN 
    Votes v ON v.PostId = qs.Id
GROUP BY 
    qs.Title, qs.DisplayName, qs.Reputation, qs.UpVotes, qs.DownVotes, qs.BadgeNames, qs.Level, qs.Id
ORDER BY 
    qs.Reputation DESC, qs.Level ASC;
