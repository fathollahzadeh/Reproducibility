
WITH UserPostStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(u.Reputation) AS AverageReputation,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
PostInteractions AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           COUNT(c.Id) AS CommentCount,
           COUNT(pl.RelatedPostId) AS RelatedPostLinks,
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
           MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
CombinedStats AS (
    SELECT ups.UserId,
           ups.DisplayName,
           ups.TotalPosts,
           ups.TotalQuestions,
           ups.TotalAnswers,
           ups.AverageReputation,
           ups.TotalUpvotes,
           ups.TotalDownvotes,
           pi.PostId,
           pi.Title,
           pi.CreationDate,
           pi.CommentCount,
           pi.RelatedPostLinks,
           pi.ClosedDate,
           pi.ReopenedDate
    FROM UserPostStats ups
    JOIN PostInteractions pi ON ups.UserId = pi.PostId  
)
SELECT *,
       CASE 
           WHEN ClosedDate IS NOT NULL THEN 'Closed'
           WHEN ReopenedDate IS NOT NULL THEN 'Reopened'
           ELSE 'Active'
       END AS PostStatus
FROM CombinedStats
WHERE AverageReputation > 100
ORDER BY TotalPosts DESC, AverageReputation DESC
LIMIT 50;
