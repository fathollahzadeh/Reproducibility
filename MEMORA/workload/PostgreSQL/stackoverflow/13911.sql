WITH PostCounts AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS TotalPosts, 
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation
    FROM 
        Users u
)
SELECT 
    ur.UserId,
    ur.Reputation,
    pc.TotalPosts,
    pc.TotalQuestions,
    pc.TotalAnswers,
    pc.TotalWikis
FROM 
    UserReputation ur
LEFT JOIN 
    PostCounts pc ON ur.UserId = pc.OwnerUserId
ORDER BY 
    ur.Reputation DESC, 
    pc.TotalPosts DESC;