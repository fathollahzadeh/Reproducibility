WITH PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10  
),
TagEngagement AS (
    SELECT 
        PT.TagName,
        PT.PostCount,
        PT.TotalViews,
        PT.AvgScore,
        REGEXP_REPLACE(PT.ActiveUsers, ',\s*', ' AND ') AS UserEngagement
    FROM 
        PopularTags PT
)
SELECT 
    TE.TagName,
    TE.PostCount,
    TE.TotalViews,
    TE.AvgScore,
    'Active users: ' || TE.UserEngagement AS EngagementDetails
FROM 
    TagEngagement TE
ORDER BY 
    TE.TotalViews DESC, TE.AvgScore DESC
LIMIT 10;