
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
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0
),
PostDetails AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        COALESCE(up.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(up.BadgeNames, 'None') AS UserBadgeNames,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        UserBadges up ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON v.PostId = ph.PostId
)
SELECT 
    pd.Title,
    pd.Level,
    pd.UserBadgeCount,
    pd.UserBadgeNames,
    pd.VoteCount,
    COALESCE(pv.Title, 'Top Level') AS ParentPostTitle
FROM 
    PostDetails pd
LEFT JOIN 
    Posts pv ON pd.PostId = pv.Id
ORDER BY 
    pd.Level DESC, pd.VoteCount DESC;
