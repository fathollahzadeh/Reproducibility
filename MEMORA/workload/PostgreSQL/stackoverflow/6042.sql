
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CreationDate,
        CASE
            WHEN ViewRank <= 10 THEN 'Top Views'
            WHEN ScoreRank <= 10 THEN 'Top Score'
            ELSE 'Others'
        END AS PostCategory
    FROM 
        RankedPosts
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    t.CreationDate,
    t.PostCategory
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON t.PostId = c.PostId
LEFT JOIN 
    Votes v ON t.PostId = v.PostId
GROUP BY 
    t.PostId, t.Title, t.ViewCount, t.Score, t.CreationDate, t.PostCategory
HAVING 
    t.PostCategory = 'Top Views' OR t.PostCategory = 'Top Score'
ORDER BY 
    t.PostCategory DESC, t.ViewCount DESC, t.Score DESC;
