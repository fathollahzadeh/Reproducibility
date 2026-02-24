WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankTotalPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT UserId, DisplayName, TotalPosts, TotalQuestions, TotalAnswers, TotalBounty
    FROM UserStatistics
    WHERE RankTotalPosts <= 10
),
PostWithHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        PHT.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentHistory
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    INNER JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalBounty,
    COALESCE(ph.Title, 'No Posts') AS RecentlyEditedPost,
    ph.HistoryDate,
    ph.HistoryType,
    ph.Comment
FROM Users u
LEFT JOIN TopActiveUsers ua ON u.Id = ua.UserId
LEFT JOIN PostWithHistory ph ON u.Id = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = ph.PostId LIMIT 1)
WHERE u.Reputation > (
    SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL
) AND (ua.TotalPosts IS NOT NULL OR ph.PostId IS NOT NULL)
ORDER BY u.Reputation DESC, ua.TotalPosts DESC
LIMIT 50;