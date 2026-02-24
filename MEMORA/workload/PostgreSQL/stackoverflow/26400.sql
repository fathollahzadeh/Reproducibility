WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Tags) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalPositivePosts,
    PT.TagName AS PopularTag,
    PA.Title AS PopularPostTitle,
    PA.ViewCount AS PopularPostViewCount,
    PA.CommentCount AS PopularPostCommentCount,
    PA.VoteCount AS PopularPostVoteCount
FROM 
    UserPostStats UPS
CROSS JOIN 
    PopularTags PT
JOIN 
    PostActivity PA ON PA.ViewCount = (SELECT MAX(ViewCount) FROM PostActivity)
ORDER BY 
    UPS.TotalPosts DESC, 
    PA.ViewCount DESC
LIMIT 10;