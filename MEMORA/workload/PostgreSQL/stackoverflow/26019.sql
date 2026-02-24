WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        STRING_AGG(DISTINCT CASE WHEN p.OwnerUserId IS NOT NULL THEN u.DisplayName END, ', ') AS TopUsers,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        TopUsers,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
Benchmark AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        TopUsers,
        CASE 
            WHEN ScoreRank <= 5 THEN 'High Score'
            WHEN ViewRank <= 5 THEN 'High Views'
            ELSE 'Moderate'
        END AS BenchmarkCategory
    FROM 
        TopTags
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    TopUsers,
    BenchmarkCategory
FROM 
    Benchmark
WHERE 
    BenchmarkCategory IN ('High Score', 'High Views')
ORDER BY 
    TotalScore DESC, TotalViews DESC;
