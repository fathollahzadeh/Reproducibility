WITH TagSplit AS (
    SELECT 
        Id AS PostId, 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
),
TagSummary AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        TagSplit
    JOIN 
        Posts ON TagSplit.PostId = Posts.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagSummary
)
SELECT 
    T.Tag,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    (SELECT COUNT(*) FROM Posts P WHERE P.Tags LIKE '%' || T.Tag || '%') AS TotalPosts,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId IN (SELECT PostId FROM TagSplit WHERE Tag = T.Tag)) AS CommentCount
FROM 
    TopTags T
WHERE 
    T.TagRank <= 10  
ORDER BY 
    T.TagRank;