WITH RankedPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.Body,
           P.CreationDate,
           P.Score,
           U.DisplayName AS OwnerDisplayName,
           COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS UpVoteCount,
           COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS DownVoteCount,
           COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
           ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.Body, P.CreationDate, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT PostId, Title, Body, CreationDate, Score, OwnerDisplayName, UpVoteCount, DownVoteCount, CommentCount
    FROM RankedPosts
    WHERE Rank <= 10
),
PostHistoryDetails AS (
    SELECT PH.PostId,
           MAX(PH.CreationDate) AS LastEditDate,
           MAX(PHT.Name) AS LastEditType
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT TP.*,
       PHD.LastEditDate,
       PHD.LastEditType
FROM TopPosts TP
LEFT JOIN PostHistoryDetails PHD ON TP.PostId = PHD.PostId
ORDER BY TP.Score DESC, TP.CreationDate DESC;
