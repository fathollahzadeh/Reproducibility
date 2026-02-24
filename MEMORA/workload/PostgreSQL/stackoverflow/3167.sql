WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),

TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, CreationDate, CommentCount, UpVoteCount, DownVoteCount, ScoreRank
    FROM 
        PostMetrics
    WHERE 
        Score > (SELECT AVG(Score) FROM PostMetrics)  
    ORDER BY 
        ScoreRank
    LIMIT 10
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    pt.Name AS PostType,
    CASE 
        WHEN tp.CommentCount > 5 THEN 'Highly Engaged'
        WHEN tp.Score > 100 THEN 'Popular'
        ELSE 'Standard'
    END AS EngagementLevel
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT DISTINCT p.PostTypeId FROM Posts p WHERE p.Id = tp.PostId)
WHERE 
    tp.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
ORDER BY 
    tp.Score DESC;