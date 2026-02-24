
WITH RECURSIVE RecursivePosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.LastActivityDate,
        1 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 
    UNION ALL
    SELECT 
        p2.Id AS PostId, 
        p2.Title, 
        p2.OwnerUserId, 
        p2.LastActivityDate,
        rp.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePosts rp ON p2.ParentId = rp.PostId
    WHERE 
        p2.PostTypeId = 2 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0 END) AS UpvoteRatio
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName, 
    ua.PostsCount,
    ua.TotalBounty,
    ua.UpvoteRatio,
    COUNT(DISTINCT rp.PostId) AS RelatedPostCount,
    MAX(rp.LastActivityDate) AS LastActivityDate
FROM 
    UserActivity ua
JOIN 
    Users u ON u.Id = ua.UserId
LEFT JOIN 
    RecursivePosts rp ON rp.OwnerUserId = u.Id
WHERE 
    ua.PostsCount > 0
GROUP BY 
    u.DisplayName, ua.PostsCount, ua.TotalBounty, ua.UpvoteRatio
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    ua.UpvoteRatio DESC, LastActivityDate DESC;
