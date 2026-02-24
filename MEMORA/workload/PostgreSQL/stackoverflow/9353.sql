
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes,
        COUNT(B.Id) AS BadgeCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE P.PostTypeId = 1  
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    COALESCE(PH.LastEditDate, '1970-01-01') AS LastEditDate,
    COALESCE(PH.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(PH.SuggestedEditCount, 0) AS SuggestedEditCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = PS.PostId AND V.VoteTypeId = 1) AS AcceptedAnswerCount,
    (SELECT COUNT(*) FROM PostLinks PL WHERE PL.PostId = PS.PostId) AS RelatedPostCount
FROM PostStatistics PS
LEFT JOIN PostHistoryAnalysis PH ON PS.PostId = PH.PostId
ORDER BY PS.UpVotes DESC, PS.CommentCount DESC
FETCH FIRST 100 ROWS ONLY;
