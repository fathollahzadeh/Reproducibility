WITH UserReputation AS (
    SELECT 
        Id, 
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        MAX(P.CreationDate) AS LatestActivity
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title
), 
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(PH.Id) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
), 
AggregateData AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.TotalViews,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        R.ReputationRank
    FROM PostStatistics PS
    LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
    JOIN UserReputation R ON R.Id = PS.PostId
)

SELECT 
    AD.Title,
    AD.UpVotes,
    AD.DownVotes,
    AD.CommentCount,
    AD.TotalViews,
    AD.CloseCount,
    CASE 
        WHEN AD.UpVotes > AD.DownVotes THEN 'Positive'
        WHEN AD.UpVotes < AD.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN AD.TotalViews > 1000 THEN 'High'
        WHEN AD.TotalViews BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ViewCategory
FROM AggregateData AD
WHERE AD.ReputationRank <= 100
ORDER BY AD.CloseCount DESC, AD.Title
LIMIT 10;

