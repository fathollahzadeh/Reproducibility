
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        RankPerUser <= 5 
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    COALESCE(ph.Comment, '') AS LastEditComment,
    COUNT(DISTINCT ph.UserId) AS EditorsCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = tp.PostId)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount, ph.Comment
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 50;
