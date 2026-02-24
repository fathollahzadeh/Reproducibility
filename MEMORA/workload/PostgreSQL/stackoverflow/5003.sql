WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate >= '2020-01-01'
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TagWikis,
        TotalScore,
        TotalViews,
        TotalBadges,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalScore DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.Questions,
    AU.Answers,
    AU.TagWikis,
    AU.TotalScore,
    AU.TotalViews,
    AU.TotalBadges
FROM 
    ActiveUsers AU
WHERE 
    AU.Rank <= 10
ORDER BY 
    AU.Rank;
