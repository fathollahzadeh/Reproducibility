
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS TotalCloseVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalComments,
        TotalBadges,
        TotalUpvotes,
        TotalDownvotes,
        TotalCloseVotes,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalUpvotes - TotalDownvotes DESC) AS UserRank
    FROM UserPostStats
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalComments,
    ru.TotalBadges,
    ru.TotalUpvotes,
    ru.TotalDownvotes,
    ru.TotalCloseVotes,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = ru.UserId AND p.ClosedDate IS NOT NULL) AS ClosedPosts,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = ru.UserId AND p.FavoriteCount > 0) AS FavoritePosts
FROM RankedUsers ru
WHERE ru.UserRank <= 10
ORDER BY ru.UserRank;
