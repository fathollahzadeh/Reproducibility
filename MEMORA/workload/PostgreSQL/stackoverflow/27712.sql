WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT U.Id) AS UserCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UserCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        T.TagName,
        P.Score AS PostScore,
        COALESCE(CNT.CommentCount, 0) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments GROUP BY PostId) CNT ON CNT.PostId = P.Id
    WHERE 
        P.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    ORDER BY 
        P.CreationDate DESC
)
SELECT 
    T.TagName,
    T.PostCount,
    T.UserCount,
    T.TotalViews,
    T.AvgScore,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.ViewCount,
    R.CommentCount
FROM 
    TopTags T
JOIN 
    RecentPosts R ON T.TagName = R.TagName
WHERE 
    T.Rank <= 10  
ORDER BY 
    T.Rank, R.CreationDate DESC;