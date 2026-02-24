WITH TagAggregates AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AvgScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS Contributors
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%')
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagAggregates
    WHERE 
        PostCount > 0
),
TopContributors AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS ContributedPosts,
        SUM(Posts.ViewCount) AS TotalViews
    FROM 
        Users
    JOIN 
        Posts ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        Users.DisplayName
    ORDER BY 
        ContributedPosts DESC
    LIMIT 10
)

SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AvgScore,
    c.DisplayName AS TopContributor,
    c.ContributedPosts,
    c.TotalViews AS ContributorTotalViews
FROM 
    TopTags t
LEFT JOIN 
    TopContributors c ON c.ContributedPosts = (
        SELECT MAX(ContributedPosts)
        FROM TopContributors
    )
WHERE 
    t.Rank <= 10
ORDER BY 
    t.PostCount DESC;