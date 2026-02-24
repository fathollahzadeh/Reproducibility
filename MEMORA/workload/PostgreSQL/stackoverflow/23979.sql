
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostWithHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 12) 
),
PostClosureReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostWithHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.HistoryRank = 1
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rb.GoldBadges, 0) AS GoldBadges,
    COALESCE(rb.SilverBadges, 0) AS SilverBadges,
    COALESCE(rb.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(rp.PostId, 0) AS TopScoringPostId,
    COALESCE(rp.Title, 'No Posts') AS TopScoringPostTitle,
    COALESCE(rp.Score, 0) AS TopScoringPostScore,
    COALESCE(pcr.CloseReason, 'Not Closed') AS RecentPostCloseReason,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Posts x 
            WHERE x.OwnerUserId = u.Id 
            AND x.CreationDate < CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
        ) THEN 'Has Legacy Posts'
        ELSE 'No Legacy Posts'
    END AS LegacyPostStatus
FROM 
    Users u
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostClosureReasons pcr ON pcr.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id
    )
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.Id, 
    u.DisplayName,
    rb.GoldBadges, 
    rb.SilverBadges,
    rb.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    pcr.CloseReason,
    u.Reputation
ORDER BY 
    u.Reputation DESC, 
    u.DisplayName ASC;
