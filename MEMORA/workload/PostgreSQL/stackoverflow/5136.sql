WITH TopUsers AS (
    SELECT Id, DisplayName, Reputation,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
    WHERE Reputation > 1000
),
PopularPosts AS (
    SELECT p.Id, p.OwnerUserId, p.Title, p.Score, p.ViewCount,
           RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PopularityRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
      AND p.PostTypeId = 1
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score,
           COUNT(c.Id) AS CommentCount, COUNT(v.Id) AS VoteCount,
           MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.PostTypeId IN (1, 2) 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score
),
FinalResults AS (
    SELECT tu.DisplayName, pp.Title, pp.Score, pd.CommentCount, pd.VoteCount, 
           pd.LastEditDate, ROW_NUMBER() OVER (PARTITION BY tu.ReputationRank ORDER BY pp.PopularityRank) AS RowNum
    FROM TopUsers tu
    JOIN PopularPosts pp ON tu.Id = pp.OwnerUserId
    JOIN PostDetails pd ON pp.Id = pd.PostId
)
SELECT DisplayName, Title, Score, CommentCount, VoteCount, LastEditDate
FROM FinalResults
WHERE RowNum <= 5
ORDER BY DisplayName, Score DESC;