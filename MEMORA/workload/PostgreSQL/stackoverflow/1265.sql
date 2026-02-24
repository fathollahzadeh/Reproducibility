
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR' 
        AND p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    COALESCE(pb.BadgeCount, 0) AS UserBadges,
    COALESCE(pb.GoldBadges, 0) AS GoldBadges,
    COALESCE(pb.SilverBadges, 0) AS SilverBadges,
    COALESCE(pb.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(vp.UpVotesCount, 0) AS UpVotesCount,
    COALESCE(vp.DownVotesCount, 0) AS DownVotesCount,
    rp.ViewCount,
    rp.Score
FROM 
    Users u
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
JOIN 
    RankedPosts rp ON u.Id = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    )
LEFT JOIN 
    PostVotes vp ON rp.PostId = vp.PostId
WHERE 
    rp.rn = 1 
    AND (u.Reputation > 1000 OR COALESCE(pb.BadgeCount, 0) > 0)
ORDER BY 
    rp.Score DESC, u.DisplayName;
