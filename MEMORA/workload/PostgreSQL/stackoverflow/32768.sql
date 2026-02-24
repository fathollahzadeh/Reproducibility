WITH RecursivePostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        CAST(NULL AS VARCHAR(400)) AS PreviousAction,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RowNum
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12)  
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    U.DisplayName AS UserName,
    U.PostsCreated,
    U.TotalScore,
    U.AvgViewCount,
    P.Title AS PostTitle,
    PH.PostHistoryTypeId,
    PH.CreationDate AS ActionDate,
    CASE 
        WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
        WHEN PH.PostHistoryTypeId = 12 THEN 'Deleted'
        ELSE 'Other Action'
    END AS ActionType,
    T.TagName AS PostTag,
    TS.PostCount AS TagPostCount,
    TS.TotalViews AS TagTotalViews
FROM 
    UserActivity U
INNER JOIN 
    RecursivePostHistory PH ON U.UserId = PH.PostId
INNER JOIN 
    Posts P ON P.Id = PH.PostId
LEFT JOIN 
    Tags T ON P.Tags LIKE '%' || T.TagName || '%'
LEFT JOIN 
    TagStats TS ON T.TagName = TS.TagName
WHERE 
    U.TotalScore > 0
ORDER BY 
    U.TotalScore DESC, PH.CreationDate DESC;