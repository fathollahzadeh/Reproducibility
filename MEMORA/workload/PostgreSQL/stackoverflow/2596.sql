WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        AVG(p.Score) AS AvgScore
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
        AcceptedQuestions,
        AvgScore,
        RANK() OVER (ORDER BY AvgScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.AcceptedQuestions,
    t.AvgScore,
    pv.Upvotes,
    pv.Downvotes,
    COALESCE(pv.Upvotes - pv.Downvotes, 0) AS NetVotes
FROM 
    TopUsers t
JOIN 
    PostVotes pv ON pv.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = t.UserId)
LEFT JOIN 
    Users u ON u.Id = t.UserId
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.AvgScore DESC;
