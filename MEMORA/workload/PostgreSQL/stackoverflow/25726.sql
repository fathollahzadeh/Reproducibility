
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT U.DisplayName) AS TopContributors,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        T.Count > 1 
    GROUP BY 
        T.TagName
),

PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(MAX(PA.UserDisplayName), 'No Activity') AS LastEditor,
        MAX(PA.CreationDate) AS LastEditedDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PA ON P.Id = PA.PostId AND PA.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        P.Id, P.Title, P.CreationDate
),

FinalBenchmark AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.TotalViews,
        TS.AverageScore,
        TS.TopContributors,
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.LastEditor,
        PA.LastEditedDate,
        PA.CommentCount
    FROM 
        TagStats TS
    JOIN 
        PostActivity PA ON PA.PostId IS NOT NULL
    ORDER BY 
        TS.TotalViews DESC, 
        TS.AverageScore DESC
)

SELECT 
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    TopContributors,
    PostId,
    Title,
    CreationDate,
    LastEditor,
    LastEditedDate,
    CommentCount
FROM 
    FinalBenchmark
LIMIT 100;
