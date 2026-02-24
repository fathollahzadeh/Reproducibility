WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE 
                WHEN b.Class = 1 THEN 1 
                ELSE 0 
            END) AS GoldBadges,
        SUM(CASE 
                WHEN b.Class = 2 THEN 1 
                ELSE 0 
            END) AS SilverBadges,
        SUM(CASE 
                WHEN b.Class = 3 THEN 1 
                ELSE 0 
            END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    up.DisplayName AS UserName,
    up.BadgeCount,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    RankedPosts rp
JOIN 
    UserBadges up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryStats phs ON rp.Id = phs.PostId AND phs.PostHistoryTypeId = 10 
WHERE 
    rp.PostRank = 1 
    AND (phs.HistoryCount IS NULL OR phs.HistoryCount < 5)  
ORDER BY 
    up.BadgeCount DESC, 
    rp.Score DESC
LIMIT 10;