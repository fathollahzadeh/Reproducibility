
WITH UserActivity AS (
    SELECT u.Id AS UserId,
           u.Reputation,
           u.DisplayName,
           COUNT(p.Id) AS PostCount,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT UserId,
           DisplayName,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserActivity
    WHERE PostCount > 5
)
SELECT u.DisplayName,
       COALESCE(NULLIF(p.Title, ''), 'No Title') AS PostTitle,
       COUNT(c.Id) AS CommentCount,
       AVG(v.BountyAmount) AS AvgBounty,
       ARRAY_AGG(DISTINCT t.TagName) AS Tags,
       RANK() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS UserScoreRank
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
WHERE u.Id IN (SELECT UserId FROM TopUsers WHERE Rank <= 10)
GROUP BY u.DisplayName, p.Title, u.Id
ORDER BY AvgBounty DESC, u.DisplayName;
