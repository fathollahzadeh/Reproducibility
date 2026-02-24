WITH RankedPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Score,
           P.ViewCount,
           U.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT PostId,
           Title,
           CreationDate,
           Score,
           ViewCount,
           OwnerDisplayName
    FROM RankedPosts
    WHERE Rank <= 5
),
PostComments AS (
    SELECT C.PostId,
           COUNT(C.Id) AS TotalComments,
           AVG(C.Score) AS AverageCommentScore
    FROM Comments C
    GROUP BY C.PostId
),
FinalResults AS (
    SELECT TP.PostId,
           TP.Title,
           TP.CreationDate,
           TP.Score,
           TP.ViewCount,
           TP.OwnerDisplayName,
           PC.TotalComments,
           PC.AverageCommentScore
    FROM TopPosts TP
    LEFT JOIN PostComments PC ON TP.PostId = PC.PostId
)
SELECT *,
       (CASE 
            WHEN Score >= 1000 THEN 'High Score'
            WHEN Score >= 500 THEN 'Medium Score'
            ELSE 'Low Score'
        END) AS ScoreCategory
FROM FinalResults
ORDER BY Score DESC, ViewCount DESC;