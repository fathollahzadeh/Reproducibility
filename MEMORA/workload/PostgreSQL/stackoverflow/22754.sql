WITH UserActivity AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalPositiveScores,
           AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
FilteredUsers AS (
    SELECT *,
           CASE 
              WHEN Reputation < 100 THEN 'Newbie'
              WHEN Reputation BETWEEN 100 AND 1000 THEN 'Contributor'
              ELSE 'Guru'
           END AS UserLevel
    FROM UserActivity
    WHERE TotalPosts > 5
),
PostScoreClean AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           p.ViewCount,
           (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL) AS AvgPostScore,
           (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id) AS VoteCount
    FROM Posts p
    WHERE (Score IS NOT NULL AND Score > 0)
),
ActivePosts AS (
    SELECT p.Id AS PostId,
           COALESCE(pl.RelatedPostId, 0) AS RelatedPostId,
           p.CreationDate,
           CASE
              WHEN p.Score IS NULL THEN 'No Score'
              WHEN p.Score < 10 THEN 'Low Score'
              ELSE 'High Score' 
           END AS ScoreCategory
    FROM Posts p
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
QuestionStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           COUNT(DISTINCT c.Id) AS CommentCount,
           AVG(v.BountyAmount) AS AvgBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title
)
SELECT f.UserId,
       f.DisplayName,
       f.UserLevel,
       pa.PostId,
       pa.RelatedPostId,
       ps.Title,
       ps.CommentCount,
       ps.AvgBounty,
       CASE
           WHEN pa.ScoreCategory = 'No Score' THEN 'Unranked'
           ELSE pa.ScoreCategory
       END AS PostScoreCategory
FROM FilteredUsers f
JOIN ActivePosts pa ON pa.PostId IN (SELECT PostId FROM QuestionStats)
JOIN QuestionStats ps ON pa.PostId = ps.PostId
ORDER BY f.Reputation DESC, ps.CommentCount DESC, ps.AvgBounty DESC
LIMIT 100;