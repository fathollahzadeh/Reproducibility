
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PopularPosts,
        Upvotes,
        Downvotes,
        (Upvotes - Downvotes) AS VoteBalance
    FROM UserStats
    WHERE TotalPosts > 5
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PopularPosts,
        Upvotes,
        Downvotes,
        VoteBalance,
        RANK() OVER (ORDER BY VoteBalance DESC) AS Rank
    FROM PopularUsers
)
SELECT 
    ur.Rank,
    ur.DisplayName,
    ur.TotalPosts,
    ur.TotalQuestions,
    ur.TotalAnswers,
    ur.PopularPosts,
    ur.Upvotes,
    ur.Downvotes
FROM UserRankings ur
WHERE ur.Rank <= 10
ORDER BY ur.Rank;
