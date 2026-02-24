WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate) AS RankScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
      AND P.Score > 0
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBounties,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN U.Reputation IS NULL THEN 0 ELSE U.Reputation END) AS TotalReputation
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate < '2022-01-01' 
        AND (U.Reputation > 0 OR U.Location IS NOT NULL)
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistorySummaries AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryActions,
        COUNT(PH.Id) AS TotalHistoryEvents
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.AnswerCount,
    RP.ViewCount,
    TU.UserId,
    TU.DisplayName,
    TU.TotalBounties,
    TU.BadgeCount,
    TU.TotalReputation,
    COALESCE(PHS.HistoryActions, 'No History') AS PostHistory,
    COALESCE(PHS.TotalHistoryEvents, 0) AS EventCount
FROM 
    RankedPosts RP
LEFT JOIN 
    TopUsers TU ON RP.PostId IN (
        SELECT ParentId FROM Posts WHERE Id = RP.PostId
    )
LEFT JOIN 
    PostHistorySummaries PHS ON PHS.PostId = RP.PostId
WHERE 
    RP.RankScore <= 5
ORDER BY 
    RP.Score DESC, 
    TU.TotalReputation DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;