
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        PostRank
    FROM 
        UserStatistics
    WHERE 
        TotalPosts > 0
    ORDER BY 
        PostRank
    LIMIT 10
),
PostComments AS (
    SELECT 
        p.OwnerUserId AS UserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(p.TopicCount, 0) AS TopicCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopUsers u
LEFT JOIN 
    (SELECT 
         OwnerUserId AS UserId, COUNT(DISTINCT Tags) AS TopicCount 
     FROM 
         Posts 
     WHERE 
         Tags IS NOT NULL AND Tags != '' 
     GROUP BY 
         OwnerUserId) p ON u.UserId = p.UserId
LEFT JOIN 
    PostComments c ON u.UserId = c.UserId
ORDER BY 
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
