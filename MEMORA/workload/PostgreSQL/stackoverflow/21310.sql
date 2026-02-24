
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS RankByScore,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostHistoryOverview AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN TRUE ELSE FALSE END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN TRUE ELSE FALSE END) AS IsReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN TRUE ELSE FALSE END) AS IsDeleted 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    up.PostId,
    up.PostTitle,
    up.Score,
    up.ViewCount,
    up.AnswerCount,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN pho.IsClosed THEN 'Closed'
        WHEN pho.IsReopened THEN 'Reopened'
        WHEN pho.IsDeleted THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryOverview pho ON up.PostId = pho.PostId
WHERE 
    up.RankByScore <= 5  
    AND u.Reputation > 100  
    AND up.Score IS NOT NULL
ORDER BY 
    u.Reputation DESC, 
    up.Score DESC
LIMIT 50;
