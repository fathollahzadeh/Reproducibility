
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(U.Reputation) AS AvgUserReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.TagName
),
CloseReasonStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS CloseDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.CommentCount,
    TS.TotalViews,
    TS.AvgUserReputation,
    CRS.CloseDate,
    CRS.Title AS ClosedPostTitle,
    CRS.CloseReason
FROM 
    TagStatistics TS
LEFT JOIN 
    CloseReasonStatistics CRS ON CRS.PostId IN (
        SELECT P.Id 
        FROM Posts P 
        WHERE P.Tags LIKE '%' || TS.TagName || '%'
    )
ORDER BY 
    TS.TotalViews DESC, 
    TS.PostCount DESC,
    TS.AvgUserReputation DESC;
