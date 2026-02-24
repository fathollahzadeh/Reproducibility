WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
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
        TotalBounties,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        TotalPosts > 0
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalBounties,
    CASE 
        WHEN tu.TotalQuestions > tu.TotalAnswers THEN 'More Questions than Answers'
        WHEN tu.TotalQuestions < tu.TotalAnswers THEN 'More Answers than Questions'
        ELSE 'Equal Questions and Answers'
    END AS PostBalance,
    ph.CreationDate AS LastActivity
FROM 
    TopUsers tu
LEFT JOIN 
    Posts ph ON tu.UserId = ph.OwnerUserId
LEFT JOIN 
    PostHistory phs ON ph.Id = phs.PostId
WHERE 
    tu.Rank <= 10
    AND tu.Reputation > (
        SELECT AVG(Reputation) FROM UserStats
    )
ORDER BY 
    tu.Reputation DESC;
