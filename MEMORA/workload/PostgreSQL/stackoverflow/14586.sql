
WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.Score, 0) AS AnswerScore,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            ParentId, 
            SUM(Score) AS Score 
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON p.Id = v.PostId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.AnswerScore,
    pa.TotalComments,
    pa.TotalUpVotes,
    pa.TotalDownVotes,
    ROUND((pa.TotalUpVotes / NULLIF(pa.TotalUpVotes + pa.TotalDownVotes, 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostAnalytics pa
ORDER BY 
    pa.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
