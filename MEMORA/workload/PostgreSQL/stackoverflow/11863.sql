WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(p.Score) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    AVG(PostCount) AS AvgPostsPerUser,
    AVG(CommentCount) AS AvgCommentsPerUser,
    AVG(VoteCount) AS AvgVotesPerUser,
    AVG(AveragePostScore) AS AvgPostScore
FROM 
    UserMetrics;