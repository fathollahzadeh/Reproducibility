WITH ActiveUsers AS (
    SELECT Id, Reputation, DisplayName, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
           COUNT(DISTINCT CASE WHEN CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN Id END) AS RecentActivity
    FROM Users
    GROUP BY Id, Reputation, DisplayName
    HAVING SUM(UpVotes) > 100 OR SUM(DownVotes) < 20
),
PostDetails AS (
    SELECT P.Id AS PostId, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId, 
           COALESCE(P.Score, 0) AS PostScore,
           COALESCE(P.ViewCount, 0) AS PostViews, 
           COUNT(C.Id) AS CommentCount,
           COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpvoteCount,
           P.CreationDate,
           P.Title
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY P.Id, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId, 
             P.Score, P.ViewCount, P.Title, P.CreationDate
),
PostHistoryDetails AS (
    SELECT PH.PostId, MAX(PH.CreationDate) AS LastHistoryDate, 
           STRING_AGG(PHT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
),
FilteredPosts AS (
    SELECT PD.*, 
           COALESCE(PHD.HistoryTypes, 'No history') AS PostHistory,
           RANK() OVER (ORDER BY PD.PostScore DESC, PD.PostViews DESC) AS PostRank
    FROM PostDetails PD
    LEFT JOIN PostHistoryDetails PHD ON PD.PostId = PHD.PostId
)
SELECT A.Id AS UserId, A.DisplayName, A.Reputation, 
       COUNT(DISTINCT FP.PostId) AS ActivePostCount, 
       AVG(FP.PostScore) AS AveragePostScore,
       MIN(FP.CreationDate) AS FirstActivePost,
       MAX(FP.CreationDate) AS LastActivePost,
       STRING_AGG(FP.Title, '; ') AS AllActivePostTitles
FROM ActiveUsers A
LEFT JOIN FilteredPosts FP ON FP.OwnerUserId = A.Id
WHERE A.RecentActivity > 0
GROUP BY A.Id, A.DisplayName, A.Reputation
HAVING AVG(FP.PostScore) > 10
ORDER BY A.Reputation DESC, ActivePostCount DESC
FETCH FIRST 10 ROWS ONLY;