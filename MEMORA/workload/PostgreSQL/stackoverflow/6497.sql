WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, Owner, CreationDate, CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    tp.Title,
    tp.Owner,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    pt.Name AS PostType,
    COALESCE(h.RevisionCount, 0) AS RevisionCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN (
    SELECT 
        PostId, COUNT(*) AS RevisionCount
    FROM 
        PostHistory 
    GROUP BY 
        PostId
) h ON tp.PostId = h.PostId
LEFT JOIN (
    SELECT 
        UserId, COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId) = b.UserId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;