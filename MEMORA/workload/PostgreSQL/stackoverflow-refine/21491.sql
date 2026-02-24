
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        CASE 
            WHEN U.Reputation > 1000 THEN 'High'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users U
),
PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        COALESCE(MAX(P.CreationDate), CAST('1970-01-01' AS TIMESTAMP)) AS MostRecentActivity
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS HistoryTypeName,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
),
RankedPosts AS (
    SELECT 
        PA.PostId,
        PA.CommentCount,
        PA.UpVotes,
        PA.DownVotes,
        PA.AverageScore,
        PA.MostRecentActivity,
        ROW_NUMBER() OVER (ORDER BY PA.AverageScore DESC, PA.CommentCount DESC) AS Rank
    FROM PostAggregates PA
)

SELECT 
    U.DisplayName AS UserName,
    U.Id AS UserId,
    UserRep.Reputation AS UserReputation,
    UserRep.ReputationLevel AS ReputationLevel,
    RP.PostId,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.AverageScore,
    PH.HistoryTypeName,
    PH.CreationDate AS HistoryCreationDate,
    RP.MostRecentActivity
FROM Users U
JOIN UserReputation UserRep ON U.Id = UserRep.UserId
JOIN RankedPosts RP ON RP.CommentCount > 0 
LEFT JOIN PostHistoryDetails PH ON RP.PostId = PH.PostId AND PH.rn = 1
WHERE 
    UserRep.ReputationLevel IN ('High', 'Medium') 
    AND RP.AverageScore > (
        SELECT AVG(AverageScore) 
        FROM RankedPosts 
        WHERE CommentCount > 0 
    ) 
ORDER BY RP.AverageScore DESC, UserRep.Reputation DESC
LIMIT 100;
