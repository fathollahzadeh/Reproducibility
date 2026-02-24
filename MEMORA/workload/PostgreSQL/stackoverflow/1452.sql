WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.OwnerUserId,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
UserReputation AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.DisplayName,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
ClosedQuestions AS (
    SELECT ph.PostId,
           ph.CreationDate,
           ph.Comment,
           ph.UserId AS CloserId,
           ph.Text
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT u.DisplayName,
       u.Reputation,
       u.TotalBounty,
       COUNT(DISTINCT rp.PostId) AS TotalQuestions,
       AVG(rp.Score) AS AvgScore,
       SUM(CASE WHEN cq.PostId IS NOT NULL THEN 1 ELSE 0 END) AS ClosedQuestionsCount
FROM UserReputation u
JOIN RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN ClosedQuestions cq ON rp.PostId = cq.PostId
WHERE u.Reputation > 1000
GROUP BY u.DisplayName, u.Reputation, u.TotalBounty
HAVING COUNT(DISTINCT rp.PostId) > 5
ORDER BY AvgScore DESC, TotalQuestions DESC
LIMIT 10;
