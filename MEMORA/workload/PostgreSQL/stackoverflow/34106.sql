WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        p.Score,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
),
OpenCloseStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), 
                 MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END)) AS LastClosedReopened
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    ub.TotalBadges AS UserBadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pc.LastClosedReopened AS LastPostChange,
    COALESCE(phd.Comment, 'No associated comment') AS HistoryComment
FROM 
    RankedPosts up
INNER JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
LEFT JOIN 
    OpenCloseStats pc ON up.PostId = pc.PostId
LEFT JOIN 
    PostHistoryDetails phd ON up.PostId = phd.PostId AND phd.HistoryRank = 1
WHERE 
    up.Rank = 1
ORDER BY 
    up.Score DESC, ub.TotalBadges DESC;