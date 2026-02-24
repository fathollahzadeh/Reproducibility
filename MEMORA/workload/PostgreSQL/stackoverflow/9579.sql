WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        COALESCE(SUM(b.Class), 0) AS TotalBadgePoints
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
RankedUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalCommentScore,
        us.TotalBadgePoints,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC, us.TotalPosts DESC) AS UserRank
    FROM UserStats us
)

SELECT 
    ru.UserRank,
    ru.DisplayName,
    ru.Reputation,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalCommentScore,
    ru.TotalBadgePoints,
    ap.Title AS RecentlyActivePost,
    ap.CreationDate AS PostCreationDate,
    ap.Score AS PostScore,
    ap.ViewCount AS PostViewCount
FROM RankedUsers ru
LEFT JOIN ActivePosts ap ON ru.UserId = ap.OwnerUserId AND ap.rn = 1
WHERE ru.UserRank <= 100
ORDER BY ru.UserRank;