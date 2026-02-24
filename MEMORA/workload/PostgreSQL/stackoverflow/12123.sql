WITH PostCounts AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName
    FROM 
        Users u
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    pc.TotalPosts,
    pc.Questions,
    pc.Answers,
    pc.TotalScore
FROM 
    UserReputation ur
LEFT JOIN 
    PostCounts pc ON ur.UserId = pc.UserId
ORDER BY 
    ur.Reputation DESC;