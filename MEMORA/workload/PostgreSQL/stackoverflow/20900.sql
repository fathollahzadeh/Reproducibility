
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
),
UserBadges AS (
    SELECT 
        u.Id AS UserID,
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
ClosedPosts AS (
    SELECT 
        p.Id AS PostID,
        STRING_AGG(CONCAT('Reason ', ph.Comment, ' on ', CAST(ph.CreationDate AS DATE)), '; ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    cp.CloseReasons,
    CASE 
        WHEN rp.ViewCount IS NULL OR rp.CommentCount > 5 THEN 'Highly Engaged'
        WHEN rp.ViewCount < 100 AND rp.Score < 0 THEN 'Low Visibility'
        ELSE 'Standard Post'
    END AS EngagementLevel,
    NULLIF((
        SELECT AVG(v.BountyAmount)
        FROM Votes v
        WHERE v.PostId = rp.PostID
        AND v.BountyAmount IS NOT NULL
    ), 0) AS AverageBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON ub.UserID IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostID)
LEFT JOIN 
    ClosedPosts cp ON rp.PostID = cp.PostID
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC,
    ub.BadgeCount DESC;
