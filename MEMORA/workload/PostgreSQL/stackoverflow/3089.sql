
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPostTitles AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tpt.PostId,
    tpt.Title,
    COALESCE(tpt.GoldBadges, 0) AS GoldBadges,
    COALESCE(tpt.SilverBadges, 0) AS SilverBadges,
    COALESCE(tpt.BronzeBadges, 0) AS BronzeBadges,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopPostTitles tpt
LEFT JOIN 
    Comments c ON tpt.PostId = c.PostId
LEFT JOIN 
    Votes v ON tpt.PostId = v.PostId
GROUP BY 
    tpt.PostId, tpt.Title, tpt.GoldBadges, tpt.SilverBadges, tpt.BronzeBadges
HAVING 
    (COALESCE(tpt.GoldBadges, 0) + COALESCE(tpt.SilverBadges, 0) + COALESCE(tpt.BronzeBadges, 0)) > 3
ORDER BY 
    UpVotes DESC, tpt.Title ASC;
