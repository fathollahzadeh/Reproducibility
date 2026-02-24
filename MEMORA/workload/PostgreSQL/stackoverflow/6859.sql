WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        AcceptedAnswers,
        CloseVotes,
        Rank
    FROM 
        UserStats
    WHERE 
        Rank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AcceptedAnswers,
    tu.CloseVotes,
    AVG(v.BountyAmount) AS AverageBountyAmount
FROM 
    TopUsers tu
LEFT JOIN 
    Votes v ON tu.UserId = v.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, 
    tu.TotalPosts, tu.Questions, tu.Answers, tu.AcceptedAnswers, tu.CloseVotes
ORDER BY 
    tu.Reputation DESC;
