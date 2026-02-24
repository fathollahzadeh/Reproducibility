
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
)

SELECT 
    ub.UserId,
    ub.DisplayName,
    STRING_AGG(ub.BadgeName, ', ') AS Badges,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore
FROM 
    UserBadges ub
LEFT JOIN 
    RankedPosts rp ON ub.UserId = rp.OwnerUserId AND rp.rn = 1  
GROUP BY 
    ub.UserId, ub.DisplayName, rp.PostId, rp.Title, rp.CreationDate, rp.Score
ORDER BY 
    ub.DisplayName;
