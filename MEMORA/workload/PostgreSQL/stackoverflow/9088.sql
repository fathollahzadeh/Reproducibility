
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalUpvotes, 
        TotalDownvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS ActivityRank
    FROM UserActivity
    WHERE TotalPosts > 0
),
TopUsers AS (
    SELECT * FROM ActiveUsers WHERE ActivityRank <= 10
),
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS UserPostCount, 
        AVG(p.Score) AS AvgPostScore
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalUpvotes,
    t.TotalDownvotes,
    ps.UserPostCount,
    ps.AvgPostScore
FROM TopUsers t
JOIN PostStats ps ON t.UserId = ps.OwnerUserId
ORDER BY t.Reputation DESC;
