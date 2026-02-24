
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL AND 
        p.Score > 0 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(rb.GoldBadges, 0) AS GoldBadges,
    COALESCE(rb.SilverBadges, 0) AS SilverBadges,
    COALESCE(rb.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT ph.UserId) AS UniqueUsersInHistory,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
    MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
    MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS IsDeleted,
    rp.CommentCount,
    EXTRACT(DOW FROM rp.CreationDate) AS DayOfWeek,
    CASE 
        WHEN rp.ViewCount > 1000 THEN 'High Views' 
        WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium Views' 
        ELSE 'Low Views' 
    END AS ViewCountCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges rb ON rp.PostId = rb.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId 
WHERE 
    rp.Rank <= 5  
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rb.GoldBadges, rb.SilverBadges, rb.BronzeBadges, rp.CommentCount
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
