
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.UpVoteCount,
    us.DownVoteCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COUNT(DISTINCT rp.Id) AS PostCount,
    MAX(rp.Score) AS HighestPostScore,
    COUNT(DISTINCT CASE WHEN rp.rn = 1 THEN rp.Id END) AS TopPostsCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
GROUP BY 
    us.DisplayName, us.UpVoteCount, us.DownVoteCount, us.GoldBadges, us.SilverBadges, us.BronzeBadges
HAVING 
    COUNT(DISTINCT rp.Id) > 5 OR SUM(us.UpVoteCount) > 100
ORDER BY 
    us.UpVoteCount DESC, HighestPostScore DESC;
