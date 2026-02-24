
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    JOIN UserReputationCTE ur ON u.Id = ur.UserId 
    WHERE u.Reputation > ur.Reputation
),

TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
      AND p.ViewCount > 500
),

UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserId) AS LastEditorId
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    ph.EditCount,
    ph.LastEditDate,
    uv.VoteCount,
    uv.Upvotes,
    uv.Downvotes
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN TopPosts tp ON p.Id = tp.PostId
LEFT JOIN PostHistorySummary ph ON p.Id = ph.PostId
LEFT JOIN UserVotes uv ON u.Id = uv.UserId
WHERE u.Reputation > 1000 
  AND ph.EditCount > 0 
  AND EXISTS (
      SELECT 1
      FROM UserReputationCTE ur
      WHERE ur.UserId = u.Id
  )
ORDER BY u.Reputation DESC, p.Score DESC;
