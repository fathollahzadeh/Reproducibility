WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        CASE 
            WHEN p.LastEditDate IS NULL THEN 'Not Edited'
            ELSE 'Edited'
        END AS EditStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body, p.LastEditDate
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
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        rp.EditStatus,
        (SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 8) AS AverageBounty
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.PostRank <= 5 
        AND (rp.Score > 10 OR rp.ViewCount > 100)
        AND (ub.GoldBadges IS NOT NULL OR ub.SilverBadges IS NOT NULL OR ub.BronzeBadges IS NOT NULL)
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    COALESCE(fp.AverageBounty, 0) AS AverageBounty,
    fp.EditStatus,
    CASE 
        WHEN fp.GoldBadges > 0 THEN 'Gold Badge Holder'
        WHEN fp.SilverBadges > 0 THEN 'Silver Badge Holder'
        ELSE 'No Badge'
    END AS BadgeStatus,
    COALESCE(fp.Score * 1.5, 0) AS AdjustedScore
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11) 
    OR ph.CreationDate < '2022-01-01'
ORDER BY 
    fp.ViewCount DESC, 
    fp.CreationDate ASC
LIMIT 10;