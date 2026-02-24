WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighScoringUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 5
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount,
        SUM(p.ViewCount) AS TagTotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalAnswers,
    u.TotalViews,
    u.TotalScore,
    t.TagName,
    t.TagPostCount,
    t.TagTotalViews
FROM 
    HighScoringUsers u
JOIN 
    TopTags t ON u.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' || t.TagName || '%'
    )
ORDER BY 
    u.TotalScore DESC, 
    t.TagPostCount DESC;
