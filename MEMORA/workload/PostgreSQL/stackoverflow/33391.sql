
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation >= 1000 
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        ur.Reputation,
        COALESCE(cr.CloseReasonCount, 0) AS CloseCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        CloseReasonCounts cr ON rp.PostId = cr.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Score,
    pa.Reputation,
    pa.CloseCount,
    pa.BadgeNames
FROM 
    PostAnalytics pa
WHERE 
    pa.CloseCount = 0 
    AND pa.Reputation >= 1000 
ORDER BY 
    pa.Score DESC, 
    pa.Reputation DESC
LIMIT 100 OFFSET 0;
