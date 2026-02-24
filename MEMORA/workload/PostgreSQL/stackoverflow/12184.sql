
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(LENGTH(p.Body)) AS AvgBodyLength,
        MAX(p.Score) AS MaxScore,
        MAX(p.ViewCount) AS MaxViewCount,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        p.Id, p.PostTypeId
)

SELECT 
    pt.Name AS PostType,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.VoteCount) AS TotalVotes,
    AVG(ps.AvgBodyLength) AS AvgBodyLength,
    MAX(ps.MaxScore) AS MaxScoreAcrossPosts,
    MAX(ps.MaxViewCount) AS MaxViewCountAcrossPosts,
    COUNT(DISTINCT ps.PostId) AS TotalPosts,
    MIN(ps.FirstPostDate) AS FirstPostDate,
    MAX(ps.LastActivityDate) AS LastActivityDate
FROM 
    PostStats ps
JOIN 
    PostTypes pt ON ps.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
