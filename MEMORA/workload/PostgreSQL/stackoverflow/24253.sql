WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rnk,
        p.AcceptedAnswerId,
        COALESCE((SELECT MAX(v.BountyAmount)
                  FROM Votes v
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 8), 0) AS MaxBounty
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '365 DAYS'
),
UserWithBadges AS (
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
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ph.LastClosedDate,
        ph.LastReopenedDate,
        rp.MaxBounty,
        CASE 
            WHEN ph.LastClosedDate IS NOT NULL AND (ph.LastReopenedDate IS NULL OR ph.LastClosedDate > ph.LastReopenedDate) 
            THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserWithBadges ub ON rp.AcceptedAnswerId = ub.UserId
    LEFT JOIN 
        PostHistoryStats ph ON rp.PostId = ph.PostId
    WHERE 
        ub.BadgeCount > 0 OR rp.ViewCount > 1000
)
SELECT 
    Title,
    PostStatus,
    ViewCount,
    AnswerCount,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    MaxBounty
FROM 
    FinalStats
ORDER BY 
    CASE 
        WHEN PostStatus = 'Closed' THEN 1 
        ELSE 0 
    END,
    AnswerCount DESC,
    ViewCount DESC
LIMIT 100;