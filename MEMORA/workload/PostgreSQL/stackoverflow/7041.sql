
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.VoteCount,
    COALESCE(ROUND(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 2), 0) AS GoldBadges,
    COALESCE(ROUND(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 2), 0) AS SilverBadges,
    COALESCE(ROUND(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 2), 0) AS BronzeBadges
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON t.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
GROUP BY 
    t.Title, t.OwnerDisplayName, t.CreationDate, t.Score, t.ViewCount, t.CommentCount, t.VoteCount
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
