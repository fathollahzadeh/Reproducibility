
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years'
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        u.Location,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.Location
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.DisplayName,
        ur.Reputation,
        ur.Location,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.Id
    WHERE 
        rp.Rank = 1 
    ORDER BY 
        rp.Score DESC, 
        ur.Reputation DESC 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(pt.Name, ': ', ph.Comment), '; ') AS HistoryComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.DisplayName,
    pp.Reputation,
    pp.Location,
    pp.GoldBadges,
    pp.SilverBadges,
    pp.BronzeBadges,
    COALESCE(pHD.HistoryComments, 'No recent history') AS RecentHistory
FROM 
    PopularPosts pp
LEFT JOIN 
    PostHistoryDetails pHD ON pp.PostId = pHD.PostId
WHERE 
    pp.Score > 5 
    AND pp.Reputation >= 100 
ORDER BY 
    pp.Score DESC, 
    pp.Reputation DESC
LIMIT 10;
