WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM Users
),
PopularPosts AS (
    SELECT P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    AND P.Score > 5
),
RecentComments AS (
    SELECT C.PostId, COUNT(C.Id) AS CommentCount
    FROM Comments C
    WHERE C.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY C.PostId
),
TopPosts AS (
    SELECT PP.Id, PP.Title, PP.ViewCount, PP.Score, UC.Reputation, COALESCE(RC.CommentCount, 0) AS RecentComments
    FROM PopularPosts PP
    JOIN UserReputation UC ON PP.OwnerDisplayName = UC.DisplayName
    LEFT JOIN RecentComments RC ON PP.Id = RC.PostId
)
SELECT TP.Id, TP.Title, TP.ViewCount, TP.Score, TP.Reputation, TP.RecentComments
FROM TopPosts TP
WHERE TP.Reputation > 1000
ORDER BY TP.Score DESC, TP.ViewCount DESC
LIMIT 10;