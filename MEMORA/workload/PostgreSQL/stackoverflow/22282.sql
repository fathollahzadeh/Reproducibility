
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        AVG(EXTRACT(EPOCH FROM (CAST('2024-10-01 12:34:56' AS timestamp) - U.CreationDate))) AS AvgAccountAgeInSeconds
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PH.UserId
),

ClosedPosts AS (
    SELECT 
        P.Id,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.ClosedDate IS NOT NULL
    GROUP BY 
        P.Id
),

UserPostSummary AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        COALESCE(CP.ReopenCount, 0) AS ReopenCount,
        COALESCE(PH.EditCount, 0) AS EditCount,
        COALESCE(PH.LastEditDate, '1970-01-01') AS LastEditDate,
        COALESCE(PH.HistoryTypes, 'None') AS HistoryTypes,
        U.TotalBounty,
        U.AvgAccountAgeInSeconds
    FROM 
        UserStats U
    LEFT JOIN 
        ClosedPosts CP ON U.UserId = CP.Id
    LEFT JOIN 
        PostHistoryStats PH ON U.UserId = PH.UserId
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.CloseCount,
    U.ReopenCount,
    U.EditCount,
    U.LastEditDate,
    U.HistoryTypes,
    U.TotalBounty,
    ROUND(U.AvgAccountAgeInSeconds / 86400, 2) AS AvgAccountAgeInDays,
    CASE 
        WHEN U.CloseCount > U.ReopenCount THEN 'More Closed'
        WHEN U.ReopenCount > U.CloseCount THEN 'More Reopened'
        ELSE 'Balanced'
    END AS PostClosureStatus
FROM 
    UserPostSummary U
WHERE 
    U.TotalPosts > 10
ORDER BY 
    U.TotalPosts DESC, U.TotalBounty DESC;
