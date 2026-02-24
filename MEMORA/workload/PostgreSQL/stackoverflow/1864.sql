
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score >= 10
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
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    u.DisplayName,
    p.Title,
    p.Score,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    p.ViewCount,
    pc.CommentCount,
    r.Rank
FROM 
    Users u
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId
JOIN 
    Posts p ON p.Id = r.PostId
LEFT JOIN 
    UserBadges b ON b.UserId = u.Id
LEFT JOIN 
    PostComments pc ON pc.PostId = p.Id
WHERE 
    r.Rank <= 5
ORDER BY 
    p.Score DESC, u.Reputation DESC;
