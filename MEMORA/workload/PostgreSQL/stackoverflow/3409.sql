
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        AVG(COALESCE(a.AvgScore, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            AVG(Score) AS AvgScore
        FROM 
            Posts
        GROUP BY 
            OwnerUserId
    ) a ON u.Id = a.OwnerUserId
    WHERE 
        u.Reputation > 100
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
        TotalVotes,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserPostStats
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalVotes,
    t.AvgPostScore,
    ph.CommentsCount,
    COALESCE(pl.LinkedPostCount, 0) AS LinkedPosts
FROM 
    TopUsers t
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
) ph ON t.UserId = ph.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS LinkedPostCount
    FROM 
        PostLinks
    GROUP BY 
        PostId
) pl ON pl.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = t.UserId)
WHERE 
    t.VoteRank <= 10
ORDER BY 
    t.TotalVotes DESC, 
    t.AvgPostScore DESC;
