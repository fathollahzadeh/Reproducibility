
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopViewPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerName,
        a.BronzeBadges,
        a.SilverBadges,
        a.GoldBadges,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ActiveUsers a ON rp.ViewRank = 1 AND rp.OwnerName = a.DisplayName
    WHERE 
        rp.ViewCount > (SELECT AVG(ViewCount) FROM RankedPosts)
)
SELECT 
    p.Title,
    p.ViewCount,
    p.OwnerName,
    COALESCE(a.GoldBadges, 0) AS GoldBadges,
    COALESCE(a.SilverBadges, 0) AS SilverBadges,
    COALESCE(a.BronzeBadges, 0) AS BronzeBadges,
    p.CommentCount
FROM 
    TopViewPosts p
LEFT JOIN 
    ActiveUsers a ON p.OwnerName = a.DisplayName
ORDER BY 
    p.ViewCount DESC;
