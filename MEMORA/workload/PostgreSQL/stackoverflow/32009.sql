WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
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
        CASE 
            WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Has Badges'
            ELSE 'No Badges'
        END AS BadgeStatus,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.SCORE,
        p.ViewCount,
        ph.Level AS HierarchyLevel,
        us.BadgeStatus,
        us.TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY us.BadgeStatus ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        UserStats us ON p.OwnerUserId = us.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.HierarchyLevel,
    pd.BadgeStatus,
    pd.TotalBounty,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    LATERAL (SELECT 
                  unnest(string_to_array(p.Tags, '>')) AS TagName 
              FROM 
                  Posts p 
              WHERE 
                  p.Id = pd.Id) t ON TRUE
GROUP BY 
    pd.Title, pd.CreationDate, pd.Score, pd.ViewCount, pd.HierarchyLevel, pd.BadgeStatus, pd.TotalBounty
HAVING 
    pd.Score > 5 
    AND pd.ViewCount > 100
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;