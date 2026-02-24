
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.UserId,
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '6 month'
    GROUP BY 
        c.UserId, c.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.PostCount,
    ua.TotalBountyAmount,
    r.PostId,
    r.Title,
    r.ViewCount,
    rc.CommentCount,
    rc.LastCommentDate
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts r ON ua.PostCount > 0 AND u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = r.PostId)
LEFT JOIN 
    RecentComments rc ON u.Id = rc.UserId
WHERE 
    ua.TotalBountyAmount > 0 OR rc.CommentCount IS NOT NULL
ORDER BY 
    ua.PostCount DESC, ua.TotalBountyAmount DESC, r.ViewCount DESC;
