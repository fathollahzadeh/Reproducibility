
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        T.TagName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        DENSE_RANK() OVER (ORDER BY UA.TotalPosts DESC) AS PostRank
    FROM 
        UserActivity UA
    WHERE 
        UA.TotalPosts > 0
),
TopTags AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        DENSE_RANK() OVER (ORDER BY TS.PostCount DESC) AS TagRank
    FROM 
        TagStatistics TS
)

SELECT 
    TU.DisplayName,
    TU.Reputation,
    TT.TagName,
    TT.PostCount
FROM 
    TopUsers TU
JOIN 
    TopTags TT ON TU.PostRank <= 10 AND TT.TagRank <= 10
ORDER BY 
    TU.Reputation DESC, 
    TT.PostCount DESC
FETCH FIRST 50 ROWS ONLY;
