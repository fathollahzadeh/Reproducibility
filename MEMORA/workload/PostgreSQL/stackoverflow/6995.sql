
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts AS p
    LEFT JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Posts AS a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    t.AnswerCount,
    CASE 
        WHEN t.Score > 100 THEN 'Hot'
        WHEN t.Score BETWEEN 50 AND 100 THEN 'Trending'
        ELSE 'New'
    END AS PostStatus
FROM 
    TopPosts AS t
ORDER BY 
    t.ViewCount DESC, 
    t.CreationDate DESC;
