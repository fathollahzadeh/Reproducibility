WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopContributors
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
TopBadges AS (
    SELECT 
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.DisplayName
    ORDER BY 
        BadgeCount DESC
    LIMIT 10
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS Author
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.ViewCount DESC
    LIMIT 5
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AvgScore,
    TB.DisplayName AS TopContributor,
    TB.BadgeCount,
    TB.BadgeNames,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViews,
    PP.CreationDate AS PopularPostDate,
    PP.Author AS PopularPostAuthor
FROM 
    TagStats TS
JOIN 
    TopBadges TB ON TB.DisplayName = TS.TopContributors
JOIN 
    PopularPosts PP ON PP.ViewCount = (
        SELECT MAX(ViewCount) FROM PopularPosts
    )
ORDER BY 
    TS.TotalViews DESC;