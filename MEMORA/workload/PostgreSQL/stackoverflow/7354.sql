
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
),

MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalWikis,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
)

SELECT 
    mu.Rank,
    mu.DisplayName,
    mu.TotalPosts,
    mu.TotalQuestions,
    mu.TotalAnswers,
    mu.TotalWikis,
    mu.UpVotes,
    mu.DownVotes,
    CASE 
        WHEN mu.TotalQuestions > 0 THEN CAST(mu.UpVotes AS FLOAT) / mu.TotalQuestions 
        ELSE 0 
    END AS AvgUpVotesPerQuestion,
    CASE 
        WHEN mu.TotalAnswers > 0 THEN CAST(mu.DownVotes AS FLOAT) / mu.TotalAnswers 
        ELSE 0 
    END AS AvgDownVotesPerAnswer
FROM 
    MostActiveUsers mu
WHERE 
    mu.Rank <= 10
ORDER BY 
    mu.Rank;
