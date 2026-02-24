WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounties
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostsCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY
        T.Id, T.TagName
)
SELECT
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalBounties,
    T.TagId,
    T.TagName,
    T.PostsCount,
    T.TotalViews
FROM
    UserStats U
JOIN
    TagStats T ON T.PostsCount > 0
ORDER BY
    U.TotalPosts DESC, T.TotalViews DESC
LIMIT 100;