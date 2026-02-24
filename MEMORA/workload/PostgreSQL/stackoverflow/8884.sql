
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN pt.Id = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.CreationDate, p.ViewCount
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        OwnerName,
        Score,
        CreationDate,
        ViewCount,
        CommentCount,
        AnswerCount,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.OwnerName, 
    ps.Score, 
    ps.CreationDate, 
    ps.ViewCount, 
    ps.CommentCount, 
    ps.AnswerCount,
    CASE 
        WHEN ps.Rank <= 10 THEN 'Top 10'
        WHEN ps.Rank BETWEEN 11 AND 50 THEN 'Top 50'
        ELSE 'Other'
    END AS RankCategory 
FROM 
    PostStatistics ps
ORDER BY 
    ps.Rank;
