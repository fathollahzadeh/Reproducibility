WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        u.Reputation AS OwnerReputation,
        p.PostTypeId,
        p.Title,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    PostTypeId,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AvgScore,
    AVG(ViewCount) AS AvgViewCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(OwnerReputation) AS AvgOwnerReputation,
    STRING_AGG(DISTINCT Tags, ', ') AS UniqueTags
FROM 
    PostStats
GROUP BY 
    PostTypeId
ORDER BY 
    TotalPosts DESC;