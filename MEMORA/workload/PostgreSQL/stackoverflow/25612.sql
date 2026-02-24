
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS Users
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        T.TagName
),
CloseReasons AS (
    SELECT 
        P.Id AS PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        U.DisplayName AS ClosedBy
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INT) = C.Id
    LEFT JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.Reputation) AS TotalReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
    ORDER BY 
        TotalReputation DESC
    LIMIT 5
)
SELECT 
    RP.OwnerDisplayName,
    RP.Title AS LatestQuestion,
    RP.CreationDate,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore,
    CR.CloseReason,
    CR.ClosedBy,
    TU.DisplayName AS TopUser,
    TU.BadgeCount,
    TU.TotalReputation
FROM 
    RankedPosts RP
LEFT JOIN 
    TagStatistics TS ON TS.PostCount > 0
LEFT JOIN 
    CloseReasons CR ON CR.PostId = RP.PostId
LEFT JOIN 
    TopUsers TU ON TU.DisplayName = RP.OwnerDisplayName
WHERE 
    RP.rn = 1
ORDER BY 
    RP.CreationDate DESC
LIMIT 10;
