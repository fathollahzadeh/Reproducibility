
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserID,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.Comment, ' (', pht.Name, ')'), '; ') AS Comments,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ph.Comments,
    ph.LastUpdate
FROM 
    RankedPosts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserID
LEFT JOIN 
    PostHistoryInfo ph ON p.PostID = ph.PostId
WHERE 
    (p.PostRank = 1 OR p.Score >= 10) AND
    (u.Reputation IS NOT NULL AND u.Reputation > 100 OR u.AccountId IS NULL)
ORDER BY 
    p.Score DESC, 
    p.CreationDate ASC;
