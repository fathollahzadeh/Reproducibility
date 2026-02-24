WITH RECURSIVE PostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), UserBadges AS (
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
), TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        PostCTE p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        p.rn = 1
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.DisplayName,
    tp.BadgeCount,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    COALESCE((
        SELECT COUNT(*)
        FROM Votes v
        WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2 
    ), 0) AS UpVotes,
    COALESCE((
        SELECT COUNT(*)
        FROM Votes v
        WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3 
    ), 0) AS DownVotes
FROM 
    TopPosts tp
ORDER BY 
    tp.BadgeCount DESC, tp.PostId;