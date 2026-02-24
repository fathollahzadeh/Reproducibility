
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1 
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerName,
        PostRank,
        CASE 
            WHEN ViewCount > 1000 THEN 'High'
            WHEN ViewCount BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ViewCategory
    FROM 
        RankedPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerName,
    ps.PostRank,
    ps.ViewCategory,
    COUNT(c.Id) AS CommentCount,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    PostStats ps
LEFT JOIN 
    Comments c ON ps.PostId = c.PostId
LEFT JOIN 
    Votes v ON ps.PostId = v.PostId
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.AnswerCount, ps.CommentCount, ps.FavoriteCount, ps.OwnerName, ps.PostRank, ps.ViewCategory
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC, ps.PostRank ASC;
