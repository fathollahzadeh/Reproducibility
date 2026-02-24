
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation, 
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score
),
PostLinksDistinct AS (
    SELECT DISTINCT 
        pl.PostId,
        pl.RelatedPostId
    FROM PostLinks pl
    WHERE pl.LinkTypeId = 3 
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    phc.HistoryCount,
    phc.LastEditDate,
    COALESCE(pl.RelatedPostId, 0) AS RelatedPostId
FROM UserReputation ur
INNER JOIN TopPosts tp ON ur.UserId = tp.OwnerUserId
LEFT JOIN PostHistoryCounts phc ON tp.PostId = phc.PostId
LEFT JOIN PostLinksDistinct pl ON tp.PostId = pl.PostId
WHERE ur.ReputationRank <= 10 AND tp.PostRank <= 5
ORDER BY ur.Reputation DESC, tp.Score DESC;
