
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.ViewCount > 100
), PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > (
            SELECT 
                AVG(Reputation) 
            FROM 
                Users 
            WHERE 
                LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
        )
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    p.Title,
    p.ViewCount,
    u.DisplayName AS Owner,
    r.CommentCount,
    p.LastActivityDate,
    CASE 
        WHEN p.ViewCount > 1000 THEN 'High' 
        WHEN p.ViewCount BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS PopularityLevel,
    CASE 
        WHEN r.rn IS NULL THEN 'No Posts' 
        ELSE CONCAT('Has Posts: ', r.rn) 
    END AS PostStatus
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PopularUsers pu ON u.Id = pu.UserId
WHERE 
    pu.UserId IS NOT NULL
ORDER BY 
    p.LastActivityDate DESC
LIMIT 50
OFFSET 0;
