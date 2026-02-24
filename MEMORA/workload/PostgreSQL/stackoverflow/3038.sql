
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, U.DisplayName
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        rp.CommentCount,
        pb.GoldBadges,
        pb.SilverBadges,
        pb.BronzeBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostBadges pb ON rp.Id = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = pb.UserId LIMIT 1)
    WHERE 
        rp.Rnk <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerName,
    tp.CommentCount,
    COALESCE(tp.GoldBadges, 0) AS TotalGoldBadges,
    COALESCE(tp.SilverBadges, 0) AS TotalSilverBadges,
    COALESCE(tp.BronzeBadges, 0) AS TotalBronzeBadges
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
