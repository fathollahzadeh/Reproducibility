
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.*,
    pt.Name AS PostType,
    COUNT(DISTINCT bh.Id) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.CommentCount, tp.Upvotes, tp.Downvotes, pt.Name
ORDER BY 
    tp.Score DESC;
