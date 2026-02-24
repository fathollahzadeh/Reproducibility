WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.DisplayName,
        U.BadgeCount,
        R.PostId,
        R.Title,
        R.Score
    FROM 
        UserReputation U
    JOIN 
        RankedPosts R ON U.UserId = R.PostId
    WHERE 
        U.Reputation > 1000 
        AND R.RankScore <= 5
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        CT.Name AS CloseReason
    FROM 
        PostHistory PH
    INNER JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  
),
FinalResults AS (
    SELECT 
        TU.DisplayName,
        TU.Reputation,
        TU.BadgeCount,
        TU.Title,
        TU.Score,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason
    FROM 
        TopUsers TU
    LEFT JOIN 
        ClosedPosts CP ON TU.PostId = CP.PostId
)
SELECT 
    DisplayName, 
    Reputation, 
    BadgeCount, 
    Title, 
    Score,
    CloseReason
FROM 
    FinalResults
ORDER BY 
    Reputation DESC, Score DESC;