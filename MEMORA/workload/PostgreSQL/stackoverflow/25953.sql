
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(COALESCE(P.Score, 0)) AS AveragePostScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        T.TagName
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10  
),
MostClosedTags AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT CR.PostId) AS ClosedPostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        CloseReasons CR ON CR.PostId = P.Id
    GROUP BY 
        T.TagName
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.PositiveScorePosts,
    TS.AveragePostScore,
    COALESCE(MCT.ClosedPostCount, 0) AS ClosedPostCount,
    TS.TopUsers
FROM 
    TagStats TS
LEFT JOIN 
    MostClosedTags MCT ON TS.TagName = MCT.TagName
ORDER BY 
    TS.AveragePostScore DESC, 
    ClosedPostCount DESC;
