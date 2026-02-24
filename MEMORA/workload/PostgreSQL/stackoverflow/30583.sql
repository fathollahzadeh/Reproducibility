
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
        p.PostTypeId = 1  
    
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
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        COUNT(DISTINCT v.Id) AS VoteCount, 
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId, 
        p.LastActivityDate,
        EXTRACT(EPOCH FROM (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - p.LastActivityDate)) / 86400 AS DaysSinceLastActivity
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
),
FinalStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ps.CommentCount,
        ps.VoteCount,
        ra.DaysSinceLastActivity,
        CASE 
            WHEN ra.DaysSinceLastActivity < 30 THEN 'Active'
            WHEN ra.DaysSinceLastActivity BETWEEN 30 AND 90 THEN 'Moderately Active'
            ELSE 'Inactive'
        END AS ActivityStatus,
        COALESCE(ps.VoteCount, 0) AS SafeVoteCount,
        COALESCE(ps.CommentCount, 0) AS SafeCommentCount
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        PostStats ps ON ph.PostId = ps.PostId
    LEFT JOIN 
        RecentActivity ra ON ph.PostId = ra.PostId
)
SELECT 
    f.Title,
    f.CommentCount,
    f.VoteCount,
    f.DaysSinceLastActivity,
    f.ActivityStatus,
    CONCAT('Post ID: ', f.PostId, ', has ', f.SafeVoteCount, ' votes and ', f.SafeCommentCount, ' comments.') AS Summary
FROM 
    FinalStats f
WHERE 
    f.ActivityStatus = 'Inactive'
ORDER BY 
    f.DaysSinceLastActivity DESC
LIMIT 50;
