WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadge
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    pc.CommentCount,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount >= 10 THEN 'Experienced Author'
        WHEN ub.BadgeCount >= 5 THEN 'Moderate Contributor'
        ELSE 'New User'
    END AS UserStatus,
    COALESCE(ll.Name, 'No Link Type') AS LinkTypeName
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    Users u ON u.Id = rp.AcceptedAnswerId
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN 
    PostLinks pl ON pl.PostId = rp.PostId
LEFT JOIN 
    LinkTypes ll ON pl.LinkTypeId = ll.Id
WHERE 
    rp.Rank <= 5 AND 
    rp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - interval '1 year'
ORDER BY 
    rp.Score DESC, CommentCount DESC;