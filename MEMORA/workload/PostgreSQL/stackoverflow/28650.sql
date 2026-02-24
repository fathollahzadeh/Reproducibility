
WITH UserTags AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS T(TagName) ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(T.TagName) AS Frequency
    FROM 
        Posts P
    JOIN 
        unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS T(TagName) ON TRUE
    GROUP BY 
        T.TagName
    ORDER BY 
        Frequency DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.PostsCreated,
        U.PostsClosed,
        UT.Tags,
        PT.TagName AS MostPopularTag
    FROM 
        UserActivity U
    JOIN 
        UserTags UT ON U.UserId = UT.UserId
    LEFT JOIN 
        PopularTags PT ON TRUE
    ORDER BY 
        U.PostsCreated DESC
)
SELECT 
    DisplayName,
    PostsCreated,
    PostsClosed,
    Tags,
    MostPopularTag
FROM 
    FinalReport
WHERE 
    MostPopularTag IS NULL;
