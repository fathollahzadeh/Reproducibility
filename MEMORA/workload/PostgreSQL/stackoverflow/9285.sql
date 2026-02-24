
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        t.TagName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT Id, unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName FROM Posts) t ON p.Id = t.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, c.CommentCount, a.AnswerCount, t.TagName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, CommentCount, AnswerCount, TagName, TotalVotes,
        DENSE_RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS ScoreRank
    FROM 
        PostStatistics
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.AnswerCount,
    p.TagName,
    p.TotalVotes,
    CASE 
        WHEN p.ScoreRank <= 10 THEN 'Top 10 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    TopPosts p
WHERE 
    p.ScoreRank <= 50  
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
