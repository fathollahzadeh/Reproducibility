
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year')
),
PopularUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS varchar)  -- Adjusting to standard SQL
    WHERE 
        PH.PostHistoryTypeId = 10 /* Post Closed */
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.Score,
    PU.DisplayName,
    PU.TotalUpvotes,
    PU.TotalDownvotes,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'None') AS CloseReasons
FROM 
    RankedPosts RP
LEFT JOIN 
    PopularUsers PU ON RP.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = RP.PostId)
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC
LIMIT 50;
