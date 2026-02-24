
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rb.UserId,
    rb.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    COALESCE(SUM(cp.CloseCount), 0) AS TotalClosedPosts,
    COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
    COALESCE(SUM(rb.GoldBadges), 0) AS TotalGoldBadges,
    COALESCE(SUM(rb.SilverBadges), 0) AS TotalSilverBadges,
    COALESCE(SUM(rb.BronzeBadges), 0) AS TotalBronzeBadges
FROM 
    UserStats rb
JOIN 
    RankedPosts rp ON rb.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rb.Reputation > 100
GROUP BY 
    rb.UserId, rb.DisplayName
ORDER BY 
    TotalPosts DESC, TotalComments DESC
LIMIT 10;
