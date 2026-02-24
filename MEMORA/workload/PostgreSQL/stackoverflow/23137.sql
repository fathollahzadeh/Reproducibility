
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
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
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosed,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName,
        u.Reputation,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        cp.LastClosed,
        cp.CloseReasons,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        ClosedPostDetails cp ON cp.PostId = rp.PostId
    WHERE 
        rp.RN <= 5
    GROUP BY 
        rp.PostId, rp.Title, u.DisplayName, u.Reputation, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, cp.LastClosed, cp.CloseReasons
)
SELECT 
    cd.*,
    CASE 
        WHEN cd.CloseReasons IS NOT NULL THEN 
            CONCAT('Closed due to ', cd.CloseReasons)
        ELSE 
            'Open'
    END AS ClosureStatus,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = cd.PostId AND v.VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = cd.PostId AND v.VoteTypeId = 3) AS Downvotes
FROM 
    CombinedData cd
ORDER BY 
    cd.Reputation DESC, 
    cd.LastClosed DESC NULLS LAST;
