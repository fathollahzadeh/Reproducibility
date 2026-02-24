
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
           COALESCE(NULLIF(p.Body, ''), 'No content available') AS BodyContent,
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM Posts p
    LEFT JOIN Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
UserPostStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT ph.PostId,
           ph.CreationDate AS CloseDate,
           ph.UserDisplayName,
           pt.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE pt.Name IN ('Post Closed', 'Post Reopened')
)
SELECT 
    up.DisplayName AS UserName,
    up.PostCount,
    up.TotalScore,
    up.AvgScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.TagsList,
    ph.CloseDate,
    ph.PostHistoryType
FROM UserPostStats up
JOIN RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN ClosedPostHistory ph ON rp.PostId = ph.PostId
WHERE up.PostCount > 5
  AND rp.ScoreRank = 1
  AND (ph.CloseDate IS NULL OR ph.CloseDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'))
ORDER BY up.TotalScore DESC, rp.CreationDate ASC
LIMIT 100 OFFSET 0;
