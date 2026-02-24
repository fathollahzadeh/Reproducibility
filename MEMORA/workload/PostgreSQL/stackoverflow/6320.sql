WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2020-01-01' 
),
ActiveBadges AS (
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
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        ab.BadgeCount,
        ab.GoldBadges,
        ab.SilverBadges,
        ab.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ActiveBadges ab ON rp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ab.UserId)
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.AnswerCount,
    pm.CommentCount,
    pm.BadgeCount,
    pm.GoldBadges,
    pm.SilverBadges,
    pm.BronzeBadges
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC;
