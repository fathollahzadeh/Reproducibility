WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostsCount,
        TotalViews,
        RANK() OVER (ORDER BY PostsCount DESC) AS TagRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagUsage
),
ActiveUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ActivePostsCount
    FROM 
        UserStats u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.UserId, u.DisplayName
),
Benchmarking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.TotalViews,
        us.TotalScore,
        tt.TagName,
        tt.PostsCount,
        tt.TotalViews AS TagTotalViews,
        au.ActivePostsCount
    FROM 
        UserStats us
    JOIN 
        TopTags tt ON us.TotalPosts > 0
    JOIN 
        ActiveUsers au ON us.UserId = au.UserId
)
SELECT 
    *,
    CASE 
        WHEN TotalScore > 100 THEN 'Top Contributor'
        WHEN TotalScore BETWEEN 50 AND 100 THEN 'Moderate Contributor'
        ELSE 'Novice Contributor'
    END AS ContributorLevel
FROM 
    Benchmarking
ORDER BY 
    TotalPosts DESC, TotalViews DESC
LIMIT 50;