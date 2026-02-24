WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.ViewCount, 
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
           COUNT(c.Id) AS TotalComments
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
), TopPosts AS (
    SELECT RP.PostId, 
           RP.Title, 
           RP.CreationDate, 
           RP.Score,
           RP.ViewCount, 
           RP.OwnerDisplayName,
           RP.TotalComments
    FROM RankedPosts RP
    WHERE RP.RankByScore <= 5
)
SELECT TP.PostId, 
       TP.Title, 
       TP.CreationDate, 
       TP.Score,
       TP.ViewCount, 
       TP.OwnerDisplayName, 
       TP.TotalComments, 
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
FROM TopPosts TP
LEFT JOIN Votes v ON TP.PostId = v.PostId
GROUP BY TP.PostId, TP.Title, TP.CreationDate, TP.Score, TP.ViewCount, TP.OwnerDisplayName, TP.TotalComments
ORDER BY TP.Score DESC, TP.ViewCount DESC;