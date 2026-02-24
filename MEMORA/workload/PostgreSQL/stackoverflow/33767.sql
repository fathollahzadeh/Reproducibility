
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.PostHistoryTypeId,
        PHT.Name AS HistoryTypeName
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CreationDate,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    rp.ViewCount,
    rp.Score,
    CASE 
        WHEN phd.PostId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS RecentlyEdited,
    ARRAY_AGG(phd.Comment) AS RecentComments
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.rn = 1 
GROUP BY 
    rp.PostId, rp.Title, u.DisplayName, rp.CreationDate, u.Reputation, ub.BadgeCount, ub.BadgeNames, rp.ViewCount, rp.Score, phd.PostId
ORDER BY 
    rp.CreationDate DESC;
