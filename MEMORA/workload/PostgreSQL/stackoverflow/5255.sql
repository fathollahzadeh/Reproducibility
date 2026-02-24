
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        TotalPosts,
        Questions,
        Answers,
        AvgScore,
        TotalViews,
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        unnest(string_to_array(p.Tags, ','))
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        PopularTags
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tu.PostRank,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.AvgScore,
    tu.TotalViews,
    tu.TotalComments,
    tt.TagName,
    tt.TagCount
FROM 
    Users u
JOIN 
    TopUsers tu ON u.Id = tu.UserId
JOIN 
    TopTags tt ON tu.PostRank = tt.TagRank
WHERE 
    tu.PostRank <= 10 
ORDER BY 
    tu.PostRank, tt.TagCount DESC;
