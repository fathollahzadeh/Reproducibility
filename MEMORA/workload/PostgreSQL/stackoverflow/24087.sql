
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
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
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        ph.CreationDate AS ClosedDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
HighScoringPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(c.CloseReasons, 'Not Closed') AS CloseReasons,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPosts c ON p.Id = c.PostId
    WHERE 
        p.Score > 100 OR p.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
)
SELECT 
    up.Id AS UserId, 
    up.DisplayName,
    up.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    hp.CloseReasons,
    CASE 
        WHEN hp.PostRank <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN up.Location IS NULL THEN 'Location Unknown'
        ELSE up.Location
    END AS UserLocation
FROM 
    Users up
JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    HighScoringPosts hp ON rp.PostId = hp.Id
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, 
    rp.ViewCount DESC;
