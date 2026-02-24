
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER(PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(DISTINCT bl.RelatedPostId) 
         FROM PostLinks bl 
         WHERE bl.PostId = p.Id) AS RelatedPostsCount,
        (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
         FROM PostHistory ph 
         JOIN PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId 
         WHERE ph.PostId = p.Id) AS HistoryTypes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        (p.PostTypeId IN (1, 2) AND p.Score >= 0)
        OR (p.PostTypeId IN (3, 4) AND p.ViewCount >= 100)
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        rp.RelatedPostsCount,
        rp.HistoryTypes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
        AND (rp.ViewCount IS NOT NULL OR rp.Score IS NOT NULL)
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    u.DisplayName AS Owner,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.ViewCount,
    fp.RelatedPostsCount,
    COALESCE(u.BadgeCount, 0) AS UserBadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    CASE 
        WHEN fp.HistoryTypes IS NULL THEN 'No activity recorded'
        ELSE fp.HistoryTypes
    END AS ActivityHistory
FROM 
    FilteredPosts fp
LEFT JOIN 
    UserStats u ON fp.OwnerUserId = u.UserId
ORDER BY 
    fp.RankScore, 
    fp.Score DESC, 
    fp.ViewCount DESC;
