
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
),
RecentVotes AS (
    SELECT 
        v.UserId,
        v.PostId,
        v.CreationDate,
        vt.Name AS VoteType,
        ROW_NUMBER() OVER (PARTITION BY v.UserId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AvgPostScore,
    COUNT(rv.UserId) FILTER (WHERE rv.VoteType = 'UpMod') AS RecentUpVotes,
    COUNT(rv.UserId) FILTER (WHERE rv.VoteType = 'DownMod') AS RecentDownVotes,
    COALESCE((SELECT SUM(Score) FROM Posts WHERE OwnerUserId = tu.UserId), 0) AS TotalPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    RecentVotes rv ON tu.UserId = rv.UserId AND rv.VoteRank <= 5
WHERE 
    tu.PostRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalQuestions, tu.TotalAnswers, tu.AvgPostScore
ORDER BY 
    tu.TotalPosts DESC, tu.AvgPostScore DESC;
