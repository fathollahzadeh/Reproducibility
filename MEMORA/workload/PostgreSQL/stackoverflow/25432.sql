WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%' )
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        TotalViews,
        AverageUserReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    CommentCount,
    TotalViews,
    AverageUserReputation,
    CASE 
        WHEN PostCount > 100 THEN 'High Engagement'
        WHEN PostCount BETWEEN 50 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopTags
WHERE 
    TagRank <= 10
ORDER BY 
    TotalViews DESC;

