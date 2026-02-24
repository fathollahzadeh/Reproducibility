
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score IS NOT NULL
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalPostScore,
        COALESCE(COUNT(b.Id), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.TotalPostScore,
    cps.CloseReasonCount,
    cps.CloseReasons,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM 
    UserReputation up
LEFT JOIN 
    ClosedPostStats cps ON up.UserId = cps.PostId
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    up.Reputation > 1000 
ORDER BY 
    up.Reputation DESC, 
    cps.CloseReasonCount DESC;
