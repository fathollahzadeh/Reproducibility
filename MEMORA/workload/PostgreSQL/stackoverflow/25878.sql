
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(LENGTH(P.Body)) AS AvgPostLength,
        SUM(P.ViewCount) AS TotalViews,
        MAX(U.Reputation) AS MaxReputation,
        MIN(U.Reputation) AS MinReputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<%', T.TagName, '> %')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        T.TagName
),
CloseReasonStatistics AS (
    SELECT 
        P.Id AS PostId,
        H.PostHistoryTypeId,
        COUNT(H.Id) AS CloseReasonCount,
        STRING_AGG(CASE WHEN H.PostHistoryTypeId = 10 THEN CR.Name END, ', ') AS CloseReasons
    FROM 
        Posts P
    JOIN 
        PostHistory H ON P.Id = H.PostId
    LEFT JOIN 
        CloseReasonTypes CR ON CAST(H.Comment AS INT) = CR.Id
    WHERE 
        H.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        P.Id, H.PostHistoryTypeId
),
CombinedStatistics AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.AvgPostLength,
        TS.TotalViews,
        C.CloseReasonCount,
        C.CloseReasons,
        TS.MaxReputation,
        TS.MinReputation,
        TS.BadgeCount
    FROM 
        TagStatistics TS
    LEFT JOIN 
        CloseReasonStatistics C ON TS.PostCount > 0  
)
SELECT 
    TagName,
    PostCount,
    AvgPostLength,
    TotalViews,
    CloseReasonCount,
    CloseReasons,
    MaxReputation,
    MinReputation,
    BadgeCount
FROM 
    CombinedStatistics
WHERE 
    PostCount > 0
ORDER BY 
    TotalViews DESC, AvgPostLength DESC;
