WITH PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
    HAVING 
        COUNT(c.Id) > 0
), TopPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pp.CreationDate,
        pp.OwnerUserId,
        pp.CommentCount,
        RANK() OVER (ORDER BY pp.Score DESC, pp.ViewCount DESC) AS Rank
    FROM 
        PopularPosts pp
)
SELECT 
    tp.PostId,
    tp.Title,
    u.DisplayName AS OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    bh.Id AS BadgeId,
    bh.Name AS BadgeName,
    bh.Class AS BadgeClass,
    COUNT(v.Id) AS VoteCount,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
WHERE 
    tp.Rank <= 10
GROUP BY 
    tp.PostId, tp.Title, u.DisplayName, tp.Score, tp.ViewCount, tp.CommentCount, bh.Id, bh.Name, bh.Class
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;