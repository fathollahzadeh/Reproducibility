WITH RECURSIVE PostHierarchy AS (
    SELECT Id, ParentId, Title, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(DISTINCT p.Id) AS PostsCount,
           SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
           AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
    GROUP BY u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT p.Id AS PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes,
           COUNT(v.Id) AS TotalVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           ph.Level,
           ps.Upvotes,
           ps.Downvotes,
           ps.CloseVotes,
           u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN PostVoteSummary ps ON p.Id = ps.PostId
    JOIN PostHierarchy ph ON p.Id = ph.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.ClosedDate IS NOT NULL
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.Level,
    cp.Upvotes,
    cp.Downvotes,
    cp.CloseVotes,
    cp.OwnerDisplayName,
    COALESCE(u.PostsCount, 0) AS UserPostsCount,
    COALESCE(u.TotalCommentScore, 0) AS UserTotalCommentScore,
    u.AvgReputation
FROM ClosedPosts cp
LEFT JOIN UserActivity u ON cp.OwnerDisplayName = u.DisplayName
ORDER BY cp.CloseVotes DESC, cp.Level ASC
FETCH FIRST 10 ROWS ONLY;
