
WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.ViewCount, 
           u.DisplayName AS Author, p.Score,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT t.TagName, COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
),
PostHistoryStats AS (
    SELECT ph.PostId, MAX(ph.CreationDate) AS LastEditedDate,
           STRING_AGG(DISTINCT pp.Name, ', ') AS PostHistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pp ON pp.Id = ph.PostHistoryTypeId
    GROUP BY ph.PostId
),
TopPosts AS (
    SELECT rp.*, pt.PostHistoryTypes, r.Id AS UserId
    FROM RecentPosts rp
    JOIN PostHistoryStats pt ON pt.PostId = rp.PostId
    JOIN Votes v ON v.PostId = rp.PostId
    JOIN Users r ON r.Id = v.UserId
    WHERE v.VoteTypeId = 2
)

SELECT 
    up.DisplayName AS UserName,
    up.Reputation,
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.Score,
    pts.LastEditedDate,
    pts.PostHistoryTypes,
    tt.TagName
FROM UserReputation up
JOIN TopPosts tp ON tp.Author = up.DisplayName
JOIN PopularTags tt ON tp.Title LIKE '%' || tt.TagName || '%'
JOIN PostHistoryStats pts ON pts.PostId = tp.PostId
WHERE up.Rank <= 10
ORDER BY up.Reputation DESC, tp.Score DESC
LIMIT 10;
