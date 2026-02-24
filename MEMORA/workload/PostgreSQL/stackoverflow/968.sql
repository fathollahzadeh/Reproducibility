WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
), 
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AverageScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        P.Id
), 
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        HT.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes HT ON PH.PostHistoryTypeId = HT.Id
    WHERE 
        HT.Name IN ('Post Closed', 'Post Reopened')
    GROUP BY 
        PH.PostId, HT.Name
), 
FinalReport AS (
    SELECT 
        US.DisplayName,
        US.Reputation,
        US.PostCount,
        PS.Title,
        PS.CreationDate,
        PS.CommentCount,
        CPS.HistoryType,
        CPS.HistoryCount,
        US.ReputationRank
    FROM 
        UserStats US
    JOIN 
        PostSummary PS ON US.UserId = PS.PostId
    LEFT JOIN 
        ClosedPostStats CPS ON PS.PostId = CPS.PostId
)
SELECT 
    DisplayName,
    Reputation,
    PostCount,
    Title,
    CreationDate,
    CommentCount,
    COALESCE(HistoryType, 'No Closure/Recovery') AS HistoryType,
    COALESCE(HistoryCount, 0) AS HistoryCount,
    ReputationRank
FROM 
    FinalReport
WHERE 
    ReputationRank <= 100
ORDER BY 
    Reputation DESC, 
    PostCount DESC;