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
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),

UserPostCount AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopPostScores AS (
    SELECT
        PostId,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1
                 WHEN vt.VoteTypeId = 3 THEN -1
                 ELSE 0 END) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1
                                                                       WHEN vt.VoteTypeId = 3 THEN -1
                                                                       ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        PostId, p.PostTypeId
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COALESCE(upc.PostCount, 0) AS UserPostCount,
    ps.Score,
    ps.Rank
FROM 
    PostHierarchy ph
LEFT JOIN 
    UserPostCount upc ON upc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    TopPostScores ps ON ps.PostId = ph.PostId
WHERE 
    ph.Level <= 2
ORDER BY 
    ph.Level, ps.Score DESC;