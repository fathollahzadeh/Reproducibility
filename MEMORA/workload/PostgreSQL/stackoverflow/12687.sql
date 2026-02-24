
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS TotalComments,
        AVG(EXTRACT(EPOCH FROM (v.CreationDate - p.CreationDate))) AS AvgVoteAge
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate, u.Reputation
)
SELECT 
    SUM(Score) AS TotalScore,
    SUM(ViewCount) AS TotalViews,
    AVG(OwnerReputation) AS AvgOwnerReputation,
    SUM(AnswerCount) AS TotalAnswers,
    SUM(CommentCount) AS TotalComments,
    COUNT(PostId) AS TotalPosts,
    MAX(CreationDate) AS LatestPostDate,
    MIN(CreationDate) AS EarliestPostDate,
    AVG(AvgVoteAge) AS AvgVoteAge
FROM 
    PostStats;
