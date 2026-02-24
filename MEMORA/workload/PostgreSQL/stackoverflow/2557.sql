WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RowNum,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswer
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.Score,
    ub.BadgeCount,
    ub.LastBadgeDate,
    pc.CommentCount,
    CASE 
        WHEN rp.AcceptedAnswer > 0 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    ub.BadgeCount > 0
    AND rp.RowNum <= 3
ORDER BY 
    rp.Score DESC, 
    up.Reputation DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
