
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),

TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
)

SELECT 
    tu.UserId,
    u.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBadges,
    COALESCE(AVG(vs.VoteCount), 0) AS AverageVotes
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
) vs ON tu.UserId = vs.OwnerUserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.UserId, u.DisplayName, tu.Reputation, 
    tu.TotalPosts, tu.TotalQuestions, 
    tu.TotalAnswers, tu.TotalBadges
ORDER BY 
    tu.Reputation DESC;
