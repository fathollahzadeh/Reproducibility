
WITH UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        us.TotalBounty,
        RANK() OVER (ORDER BY us.Reputation + us.UpVotes * 2 - us.DownVotes) AS RankScore
    FROM 
        UserScoreCTE us
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.UpVotes,
    tu.DownVotes,
    tu.TotalBounty,
    tu.RankScore,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
WHERE 
    tu.RankScore <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.UpVotes, tu.DownVotes, tu.TotalBounty, tu.RankScore
ORDER BY 
    tu.RankScore;
