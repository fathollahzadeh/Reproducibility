
WITH UserActivity AS (
  SELECT
    Users.Id AS UserId,
    Users.DisplayName,
    COUNT(DISTINCT Posts.Id) AS TotalPosts,
    SUM(COALESCE(Votes.BountyAmount, 0)) AS TotalBounty,
    RANK() OVER (ORDER BY COUNT(DISTINCT Posts.Id) DESC) AS UserRank
  FROM Users
  LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
  LEFT JOIN Votes ON Users.Id = Votes.UserId
  GROUP BY Users.Id, Users.DisplayName
),
PostStatistics AS (
  SELECT
    Posts.Id AS PostId,
    Posts.Title,
    Posts.CreationDate,
    Posts.Score,
    COUNT(Comments.Id) AS CommentCount,
    SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    COALESCE(NULLIF(Posts.AcceptedAnswerId, -1), 0) AS AcceptedAnswer
  FROM Posts
  LEFT JOIN Comments ON Posts.Id = Comments.PostId
  LEFT JOIN Votes ON Posts.Id = Votes.PostId
  GROUP BY Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score
),
ClosedPost AS (
  SELECT 
    ph.PostId,
    ph.UserId,
    ph.Comment,
    ph.CreationDate,
    RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CommentRank
  FROM PostHistory ph
  WHERE ph.PostHistoryTypeId = 10 
)
SELECT
  p.Title,
  p.Score,
  ps.TotalPosts,
  ps.TotalBounty,
  p.CommentCount,
  p.AcceptedAnswer,
  COALESCE(c.UserId, 0) AS ClosedByUserId,
  COALESCE(c.Comment, 'No closure comment') AS ClosureComment,
  COALESCE(c.CreationDate::TEXT, 'Not Closed') AS ClosureDate,
  CASE
    WHEN c.CommentRank IS NOT NULL THEN 'Closed'
    ELSE 'Open'
  END AS PostStatus
FROM PostStatistics p
JOIN UserActivity ps ON ps.UserRank <= 10
LEFT JOIN ClosedPost c ON p.PostId = c.PostId AND c.CommentRank = 1
WHERE (p.Score IS NOT NULL AND p.Score > 0)
  OR (p.CommentCount IS NOT NULL AND p.CommentCount > 5)
  OR (p.AcceptedAnswer IS NOT NULL AND p.AcceptedAnswer > 0)
ORDER BY p.Score DESC, p.CommentCount DESC
LIMIT 50;
