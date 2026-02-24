
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND (p.Score > 10 OR p.ViewCount > 1000)
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT post.Id) AS NumberOfPosts,
        COALESCE(SUM(u.Reputation), 0) AS Reputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts post ON u.Id = post.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryComments AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseComment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    u.DisplayName,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.NumberOfPosts,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    phc.CloseComment
FROM 
    UserStats u
JOIN 
    RankedPosts rp ON u.NumberOfPosts > 5
LEFT JOIN 
    PostHistoryComments phc ON rp.Id = phc.PostId AND phc.CommentRank = 1
WHERE 
    u.GoldBadges > 0
ORDER BY 
    u.Reputation DESC, 
    rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
