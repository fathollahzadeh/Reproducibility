WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
UserPostStats AS (
    SELECT 
        ur.DisplayName,
        ur.Reputation,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        COUNT(rp.Id) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.Id = rp.OwnerUserId
    GROUP BY 
        ur.DisplayName, ur.Reputation, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    ups.PostCount,
    ups.AvgScore,
    ups.TotalViews,
    COALESCE(cp.CloseCount, 0) AS TotalClosedPosts
FROM 
    UserPostStats ups
LEFT JOIN 
    ClosedPosts cp ON ups.PostCount = cp.PostId
WHERE 
    ups.Reputation > 1000
ORDER BY 
    ups.TotalViews DESC NULLS LAST
LIMIT 20;