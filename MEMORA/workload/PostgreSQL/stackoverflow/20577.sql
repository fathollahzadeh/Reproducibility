
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(p.ClosedDate, DATE '9999-12-31') AS EffectiveClosedDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
UserSummary AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(DISTINCT cht.Name, ', ') AS CloseReasons, 
        COUNT(*) AS CloseReasonCount 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        CloseReasonTypes cht ON ph.Comment::int = cht.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.Score, 
    rp.ViewCount,
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(cph.CloseReasons, 'No close reasons') AS CloseReasons,
    COALESCE(cph.CloseReasonCount, 0) AS CloseReasonCount
FROM 
    RankedPosts rp
JOIN 
    UserSummary us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPostHistory cph ON rp.PostId = cph.PostId
WHERE 
    rp.EffectiveClosedDate = DATE '9999-12-31' 
    AND (rp.Score > 10 OR us.Reputation > 100)
ORDER BY 
    rp.PostRank, us.Reputation DESC
LIMIT 50;
