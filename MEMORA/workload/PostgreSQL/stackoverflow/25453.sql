
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
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
        TotalUpVotes,
        TotalDownVotes,
        PositiveScoredPosts,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpVoteRank
    FROM 
        UserPostStats
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalUpVotes,
    t.TotalDownVotes,
    t.PositiveScoredPosts,
    p.PostRank,
    u.UpVoteRank,
    CASE 
        WHEN p.PostRank <= 10 THEN 'Top Posters'
        ELSE 'Regular Posters'
    END AS PostCategory,
    CASE 
        WHEN u.UpVoteRank <= 10 THEN 'Top Upvoted Users'
        ELSE 'Regular Upvoted Users'
    END AS VoteCategory
FROM 
    TopUsers t
JOIN 
    TopUsers p ON t.UserId = p.UserId
JOIN 
    TopUsers u ON t.UserId = u.UserId
WHERE 
    t.TotalPosts > 0 OR t.TotalUpVotes > 0 
ORDER BY 
    t.TotalPosts DESC, t.TotalUpVotes DESC;
