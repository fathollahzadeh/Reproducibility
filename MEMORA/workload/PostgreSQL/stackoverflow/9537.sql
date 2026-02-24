
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, LastAccessDate
    FROM Users
    WHERE Reputation >= 1000
),
ActivePosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
    FROM Posts p
    INNER JOIN UserReputation ur ON p.OwnerUserId = ur.Id
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopTags AS (
    SELECT t.Id, t.TagName, COUNT(p.Id) AS Count
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    GROUP BY t.Id, t.TagName
    ORDER BY COUNT(p.Id) DESC
    LIMIT 5
),
PostActivity AS (
    SELECT ph.PostId, COUNT(ph.Id) AS EditCount, MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY ph.PostId
)
SELECT ap.PostId, ap.Title, ap.CreationDate, ap.Score, ap.ViewCount, ap.AnswerCount, ap.CommentCount, 
       ta.TagName, ta.Count AS TagCount, pa.EditCount, pa.LastEditDate
FROM ActivePosts ap
LEFT JOIN PostActivity pa ON ap.PostId = pa.PostId
LEFT JOIN TopTags ta ON ap.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%<', ta.TagName, '>%' ))
ORDER BY ap.Score DESC, ap.ViewCount DESC;
