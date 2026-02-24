WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
),
PostHistoryAggregates AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId, PH.PostId
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
PostsWithVotes AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(PVS.UpVotes, 0) AS UpVotes,
        COALESCE(PVS.DownVotes, 0) AS DownVotes,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        PH.EditCount AS EditCount,
        PH.EditTypes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostVoteSummary PVS ON P.Id = PVS.PostId
    LEFT JOIN 
        PostHistoryAggregates PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
)
SELECT 
    PU.UserId,
    PU.DisplayName,
    P.PostId,
    P.Title,
    P.UpVotes,
    P.DownVotes,
    P.CreationDate,
    P.LastActivityDate,
    P.EditCount,
    P.EditTypes,
    COALESCE(P.UpVotes - P.DownVotes, 0) AS NetVotes,
    T.Rank AS UserRank
FROM 
    PostsWithVotes P
JOIN 
    TopUsers T ON P.OwnerDisplayName = T.DisplayName 
JOIN 
    UserPostStats PU ON T.UserId = PU.UserId
WHERE 
    (P.UpVotes > 0 OR P.DownVotes > 0)
    AND PU.PostCount > 5
ORDER BY 
    T.Rank, P.CreationDate DESC
LIMIT 10;