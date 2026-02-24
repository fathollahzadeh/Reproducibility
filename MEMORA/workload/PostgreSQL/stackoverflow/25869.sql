WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Tags AS t
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments AS c ON c.PostId = p.Id
    LEFT JOIN 
        Votes AS v ON v.PostId = p.Id AND v.VoteTypeId = 8  
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        AnswerCount,
        TotalViews,
        TotalBounties,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
OverallTopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        AnswerCount,
        TotalViews,
        TotalBounties,
        (PostRank + ViewRank) AS OverallRank
    FROM 
        TopTags
)
SELECT 
    TagName,
    PostCount,
    CommentCount,
    AnswerCount,
    TotalViews,
    TotalBounties,
    OverallRank,
    CASE 
        WHEN OverallRank <= 10 THEN 'Top Tag'
        WHEN OverallRank <= 20 THEN 'Mid Tag'
        ELSE 'Low Tag'
    END AS TagCategory
FROM 
    OverallTopTags
WHERE 
    PostCount > 0
ORDER BY 
    OverallRank;