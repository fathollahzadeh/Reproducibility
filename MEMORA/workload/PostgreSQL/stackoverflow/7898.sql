
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
    ORDER BY 
        rp.CreationDate DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    COALESCE(MAX(CASE WHEN b.Class = 1 THEN b.Name END), 'No Gold Badge') AS GoldBadge,
    COALESCE(MAX(CASE WHEN b.Class = 2 THEN b.Name END), 'No Silver Badge') AS SilverBadge,
    COALESCE(MAX(CASE WHEN b.Class = 3 THEN b.Name END), 'No Bronze Badge') AS BronzeBadge
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.PostId = b.UserId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate
ORDER BY 
    tp.CreationDate DESC;
