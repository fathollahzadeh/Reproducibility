WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(Cmt.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments Cmt ON P.Id = Cmt.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.CreationDate, P.Score, P.ViewCount
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastModified
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '3 months'
    GROUP BY PH.PostId, PHT.Name
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.TotalPosts,
    UR.Questions,
    UR.Answers,
    UR.Wikis,
    PS.PostId,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.VoteCount,
    PHD.HistoryType,
    PHD.HistoryCount,
    PHD.LastModified
FROM UserReputation UR
JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN PostHistoryDetails PHD ON PS.PostId = PHD.PostId
ORDER BY UR.Reputation DESC, PS.Score DESC, PS.CreationDate DESC;