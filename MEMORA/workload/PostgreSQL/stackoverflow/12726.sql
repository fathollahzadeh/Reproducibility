WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName
), TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPostsWithTag
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalBounty,
    (SELECT COUNT(*) FROM TagStats) AS UniqueTagsCount
FROM 
    UserStats US
ORDER BY 
    US.TotalPosts DESC
LIMIT 10;