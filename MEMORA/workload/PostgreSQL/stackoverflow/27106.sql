WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY T.TagName
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT V.PostId) AS VotesGiven,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        P.Id AS PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 2 THEN PH.CreationDate END) AS FirstBodyEdit,
        MAX(CASE WHEN PH.PostHistoryTypeId = 4 THEN PH.CreationDate END) AS FirstTitleEdit,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore,
    TS.CommentCount,
    UE.DisplayName,
    UE.VotesGiven,
    UE.UpVotes,
    UE.DownVotes,
    PHD.FirstBodyEdit,
    PHD.FirstTitleEdit,
    PHD.CloseCount
FROM TagStatistics TS
JOIN UserEngagement UE ON UE.UpVotes > 10 OR UE.DownVotes > 10
JOIN PostHistoryDetails PHD ON PHD.CloseCount > 0 
ORDER BY TS.TotalViews DESC, TS.AverageScore DESC
LIMIT 25;
