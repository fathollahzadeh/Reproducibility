WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, UpVotes, DownVotes, Views
    FROM Users
    WHERE Reputation > 1000
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN UserReputation u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND p.PostTypeId = 1  
    ORDER BY p.Score DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT ph.PostId, COUNT(ph.Id) AS EditCount, 
           MAX(ph.CreationDate) AS LastEdited
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT tp.Title, tp.Score, tp.ViewCount, 
       tp.OwnerDisplayName, 
       p.ClosedDate, 
       phs.EditCount, 
       phs.LastEdited
FROM TopPosts tp
LEFT JOIN Posts p ON tp.Id = p.Id
LEFT JOIN PostHistoryStats phs ON tp.Id = phs.PostId
WHERE p.ClosedDate IS NULL
ORDER BY tp.Score DESC;