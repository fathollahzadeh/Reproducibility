
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostSummary AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
UserReputation AS (
    SELECT 
        AVG(Reputation) AS AvgReputation
    FROM 
        Users
)
SELECT 
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalComments,
    ur.AvgReputation,
    COUNT(upc.UserId) AS TotalUsers,
    SUM(upc.PostCount) AS TotalPostsByUsers,
    AVG(upc.PostCount) AS AvgPostsPerUser
FROM 
    PostSummary ps,
    UserReputation ur,
    UserPostCounts upc
GROUP BY 
    ps.TotalPosts,
    ps.TotalQuestions,
    ps.TotalAnswers,
    ps.TotalComments,
    ur.AvgReputation;
