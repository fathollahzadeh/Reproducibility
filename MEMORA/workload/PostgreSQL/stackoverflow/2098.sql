
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0
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
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.GoldBadges, 0) AS GoldBadges,
        COALESCE(rb.SilverBadges, 0) AS SilverBadges,
        COALESCE(rb.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, rb.GoldBadges, rb.SilverBadges, rb.BronzeBadges
)
SELECT 
    us.DisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    p.Title AS TopPostTitle,
    p.Score AS TopPostScore
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts p ON us.UserId = p.OwnerUserId AND p.Rank = 1
WHERE 
    (us.GoldBadges + us.SilverBadges + us.BronzeBadges) > 0
ORDER BY 
    us.GoldBadges DESC, us.SilverBadges DESC, us.BronzeBadges DESC, TopPostScore DESC
LIMIT 10;
