WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT
    p.Id,
    p.Title,
    p.CreationDate,
    up.DisplayName AS OwnerDisplayName,
    COALESCE(up.Reputation, 0) AS OwnerReputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.HistoryTypes,
    phs.EditorCount,
    phs.LastEditDate,
    (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    COALESCE(rp.Rank, NULL) AS UserPostRank
FROM 
    Posts p
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
WHERE 
    phs.EditorCount > 5 
    AND (p.ClosedDate IS NULL OR p.ClosedDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days') 
ORDER BY 
    p.Score DESC, OwnerReputation DESC
LIMIT 100;