
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    t.TotalAnswers,
    COALESCE(t.TotalUpVotes, 0) AS UpVotes,
    COALESCE(t.TotalDownVotes, 0) AS DownVotes,
    CASE 
        WHEN t.ReputationRank <= 10 THEN 'Top User'
        WHEN t.ReputationRank <= 50 THEN 'Contributing User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    TopUsers t
WHERE 
    t.TotalPosts > 5
ORDER BY 
    t.Reputation DESC, t.TotalPosts DESC;
