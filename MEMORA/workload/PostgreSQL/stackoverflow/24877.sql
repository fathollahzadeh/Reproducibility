
WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS Rank,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeValue
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgScore,
        ur.TotalBadgeValue,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS OverallRank
    FROM 
        UserRankings ur
        JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.Reputation IS NOT NULL 
        AND ur.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    ROUND(tu.AvgScore, 2) AS RoundedAvgScore,
    CASE 
        WHEN tu.TotalQuestions = 0 THEN 'No questions'
        ELSE CONCAT('Post ratio: ', ROUND(tu.TotalAnswers::numeric / NULLIF(tu.TotalQuestions, 0), 2))
    END AS PostRatio,
    COALESCE((
        SELECT 
            STRING_AGG(b.Name, ', ') 
        FROM 
            Badges b
        WHERE 
            b.UserId = tu.UserId
            AND b.Class = 1  
    ), 'No Gold Badges') AS GoldBadges
FROM 
    TopUsers tu
WHERE 
    tu.OverallRank <= 10
ORDER BY 
    tu.OverallRank;
