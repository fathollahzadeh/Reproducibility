
WITH TagCounts AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END)) AS Upvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS Downvotes
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        T.IsModeratorOnly IS NOT TRUE
    GROUP BY 
        T.TagName
), 
RankedTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank,
        RANK() OVER (ORDER BY Upvotes - Downvotes DESC) AS VoteRank
    FROM 
        TagCounts
),
BenchmarkResults AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        Upvotes,
        Downvotes,
        ViewRank,
        AnswerRank,
        VoteRank,
        (PostCount * 0.4) + (TotalViews * 0.3) + (TotalAnswers * 0.2) + ((Upvotes - Downvotes) * 0.1) AS BenchmarkScore
    FROM 
        RankedTags
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalAnswers,
    Upvotes,
    Downvotes,
    BenchmarkScore,
    DENSE_RANK() OVER (ORDER BY BenchmarkScore DESC) AS OverallRank
FROM 
    BenchmarkResults
ORDER BY 
    OverallRank
LIMIT 10;
