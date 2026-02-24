WITH UserReputation AS (
    SELECT Id, Reputation,
           NTILE(10) OVER (ORDER BY Reputation DESC) AS ReputationBucket
    FROM Users
),

RecentPosts AS (
    SELECT p.Id AS PostId, p.OwnerUserId, p.CreationDate, p.Title,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),

PostStatistics AS (
    SELECT rp.OwnerUserId, 
           COUNT(rp.PostId) AS TotalPosts,
           SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS UpvotePosts,
           SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotePosts,
           AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM RecentPosts rp
    LEFT JOIN Posts p ON rp.PostId = p.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY rp.OwnerUserId
),

PostHistoryCounts AS (
    SELECT ph.UserId, 
           COUNT(*) AS TotalChanges,
           SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseChanges,
           SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS SuggestedEdits
    FROM PostHistory ph
    GROUP BY ph.UserId
),

FinalReport AS (
    SELECT u.Id AS UserId, u.DisplayName,
           ur.ReputationBucket, ur.Reputation,
           ps.TotalPosts, ps.UpvotePosts, ps.DownvotePosts, ps.AvgCommentScore,
           phc.TotalChanges, phc.CloseChanges, phc.SuggestedEdits
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN PostHistoryCounts phc ON u.Id = phc.UserId
)

SELECT fr.UserId, fr.DisplayName,
       COALESCE(fr.TotalPosts, 0) AS TotalPosts,
       COALESCE(fr.UpvotePosts, 0) AS UpvotePosts,
       COALESCE(fr.DownvotePosts, 0) AS DownvotePosts,
       COALESCE(fr.AvgCommentScore, 0) AS AvgCommentScore,
       COALESCE(fr.TotalChanges, 0) AS TotalChanges,
       COALESCE(fr.CloseChanges, 0) AS CloseChanges,
       COALESCE(fr.SuggestedEdits, 0) AS SuggestedEdits,
       CASE 
           WHEN fr.ReputationBucket IS NOT NULL AND fr.ReputationBucket <= 3 THEN 'Low Reputation'
           WHEN fr.ReputationBucket IS NOT NULL AND fr.ReputationBucket <= 7 THEN 'Medium Reputation'
           WHEN fr.ReputationBucket IS NOT NULL THEN 'High Reputation'
           ELSE 'No Reputation'
       END AS ReputationCategory
FROM FinalReport fr
WHERE fr.TotalPosts IS NULL OR fr.TotalPosts > 0
ORDER BY fr.Reputation DESC NULLS LAST, fr.TotalPosts DESC;