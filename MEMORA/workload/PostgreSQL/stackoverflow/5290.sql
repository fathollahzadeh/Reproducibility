WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.AnswerCount,
    t.CommentCount,
    t.FavoriteCount,
    t.OwnerName,
    COUNT(c.Id) AS CommentCountTotal,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
LEFT JOIN 
    Votes v ON t.PostId = v.PostId AND v.VoteTypeId = 8
GROUP BY 
    t.PostId, t.Title, t.CreationDate, t.ViewCount, t.Score, t.AnswerCount, t.CommentCount, t.FavoriteCount, t.OwnerName
ORDER BY 
    t.Score DESC, t.CreationDate DESC;