WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        p.Title,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    PostId,
    PostTypeId,
    COUNT(*) AS PostCount,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    AVG(AnswerCount) AS AvgAnswerCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(OwnerReputation) AS AvgOwnerReputation,
    SUM(TotalVotes) AS TotalVotes,
    SUM(TotalComments) AS TotalComments
FROM 
    PostMetrics
GROUP BY 
    PostId, PostTypeId
ORDER BY 
    PostCount DESC;