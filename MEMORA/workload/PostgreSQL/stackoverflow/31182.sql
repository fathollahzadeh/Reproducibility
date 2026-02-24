
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ur.Level + 1 AS Level
    FROM 
        Users u
    JOIN 
        UserReputationCTE ur ON u.Reputation > ur.Reputation
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
    AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames,
    ARRAY_AGG(DISTINCT t.TagName) AS AssociatedTags,
    MAX(b.Class) AS HighestBadgeClass
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000
    AND u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalViews DESC, u.Reputation DESC
LIMIT 10;
