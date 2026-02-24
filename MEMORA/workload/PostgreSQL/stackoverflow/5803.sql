
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount, p.AnswerCount, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, SUM(p.ViewCount) AS TotalViews, 
           SUM(p.Score) AS TotalScore, COUNT(p.Id) AS PostCount
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(p.Id) > 5
    ORDER BY TotalViews DESC
    LIMIT 10
),
PostMetrics AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, 
           COALESCE(v.UpVotes, 0) AS UpVotes, COALESCE(v.DownVotes, 0) AS DownVotes, 
           p.OwnerUserId
    FROM RecentPosts p
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
)
SELECT u.DisplayName, pm.Title, pm.Score, pm.ViewCount, pm.UpVotes, pm.DownVotes
FROM TopUsers u
JOIN PostMetrics pm ON pm.OwnerUserId = u.Id
ORDER BY u.TotalViews DESC, pm.Score DESC;
