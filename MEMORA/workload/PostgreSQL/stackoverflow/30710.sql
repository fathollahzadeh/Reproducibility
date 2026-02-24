WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND (p.Score > 0 OR p.ViewCount > 100)
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
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Edited'
        END AS ChangeType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RelatedPosts AS (
    SELECT 
        pl.PostId,
        STRING_AGG(pl.RelatedPostId::text, ', ') AS RelatedPostIds
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    r.Title,
    r.Score,
    r.ViewCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(b.BadgeNames, 'No Badges') AS BadgeNames,
    ph.ChangeType,
    ph.HistoryDate,
    rp.RelatedPostIds
FROM 
    Users up
JOIN 
    RankedPosts r ON up.Id = r.OwnerUserId
LEFT JOIN 
    UserBadges b ON up.Id = b.UserId
LEFT JOIN 
    PostHistoryDetails ph ON r.Id = ph.PostId
LEFT JOIN 
    RelatedPosts rp ON r.Id = rp.PostId
WHERE 
    r.PostRank <= 3
ORDER BY 
    up.Reputation DESC, r.Score DESC, r.CreationDate DESC;