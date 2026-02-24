
WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation,
           CASE
               WHEN Reputation >= 1000 THEN 'High'
               WHEN Reputation >= 500 THEN 'Medium'
               ELSE 'Low'
           END AS ReputationLevel
    FROM Users
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.ViewCount, p.Score,
           u.DisplayName AS Author, COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE('2024-10-01') - INTERVAL '90 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
PostHistorySummary AS (
    SELECT ph.PostId, COUNT(ph.Id) AS EditCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
FinalResults AS (
    SELECT pd.*, u.ReputationLevel, COALESCE(phs.EditCount, 0) AS TotalEdits
    FROM PostDetails pd
    JOIN UserReputation u ON pd.Author = u.DisplayName
    LEFT JOIN PostHistorySummary phs ON pd.PostId = phs.PostId
)

SELECT *,
       CASE
           WHEN TotalEdits > 5 THEN 'Highly Edited'
           WHEN TotalEdits BETWEEN 1 AND 5 THEN 'Moderately Edited'
           ELSE 'Seldom Edited'
       END AS EditFrequency
FROM FinalResults
WHERE Score > 10
ORDER BY Score DESC, ViewCount DESC
LIMIT 10
OFFSET 0;
