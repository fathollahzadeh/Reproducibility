
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    rb.BadgeCount,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    ph.EditCount,
    ph.LastEditDate,
    c.CloseReason,
    c.ClosedDate,
    au.DisplayName AS ActiveUser,
    au.PostsCount,
    au.TotalBounty
FROM 
    RankedPosts p
LEFT JOIN 
    UserBadges rb ON p.OwnerUserId = rb.UserId
LEFT JOIN 
    PostHistoryCounts ph ON p.PostId = ph.PostId
LEFT JOIN 
    ClosedPosts c ON p.PostId = c.PostId
LEFT JOIN 
    MostActiveUsers au ON p.OwnerUserId = au.UserId
WHERE 
    p.RankByScore <= 5
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
