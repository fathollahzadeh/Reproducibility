WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
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
        rp.OwnerName,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
    ORDER BY 
        rp.Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(v.VoteCount, 0) AS VoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount
     FROM Badges
     GROUP BY UserId) b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     WHERE VoteTypeId = 2 
     GROUP BY PostId) v ON tp.PostId = v.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;