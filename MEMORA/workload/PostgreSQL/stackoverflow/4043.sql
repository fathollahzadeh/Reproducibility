
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    us.TotalQuestions,
    us.Upvotes,
    us.Downvotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.Title AS LastPostTitle,
    rp.CreationDate AS LastPostDate
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id AND rp.PostRank = 1
WHERE 
    us.TotalQuestions > 0
ORDER BY 
    us.Upvotes - us.Downvotes DESC, 
    LastPostDate DESC
LIMIT 10;
