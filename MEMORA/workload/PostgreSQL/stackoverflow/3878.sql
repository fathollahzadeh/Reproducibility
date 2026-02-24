WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking 
    FROM Users
),
PostStatistics AS (
    SELECT OwnerUserId, COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews,
           SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate,
           CASE WHEN p.ClosedDate IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus
    FROM Posts p
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
HighlyActiveUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation
    FROM UserReputation u
    JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    WHERE ps.QuestionCount + ps.AnswerCount > 10
),
ClosedPostReasons AS (
    SELECT ph.PostId, ph.Comment AS CloseReason, 
           ph.CreationDate AS CloseDate, 
           u.DisplayName AS ClosedBy
    FROM PostHistory ph
    JOIN Users u ON ph.UserId = u.Id
    WHERE ph.PostHistoryTypeId = 10
)
SELECT u.DisplayName AS UserName, 
       ps.QuestionCount, 
       ps.AnswerCount, 
       ps.TotalViews,
       ps.TotalScore,
       rp.Title AS RecentPostTitle,
       rp.PostStatus,
       CPR.CloseReason,
       CPR.CloseDate,
       CPR.ClosedBy
FROM HighlyActiveUsers u
LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentPosts rp ON ps.OwnerUserId = rp.Id
LEFT JOIN ClosedPostReasons CPR ON CPR.PostId = rp.Id
WHERE ps.TotalViews > 1000
ORDER BY ps.TotalScore DESC, ps.TotalViews DESC;