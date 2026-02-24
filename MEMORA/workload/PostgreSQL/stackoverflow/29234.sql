WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        STRING_AGG(DISTINCT p.Title, ', ') AS TopPostTitles,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Tags AS t
    JOIN 
        Posts AS p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments AS c ON c.PostId = p.Id
    LEFT JOIN 
        Votes AS v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        HighViewCountPosts,
        TotalComments,
        TotalBountyAmount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, HighViewCountPosts DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.HighViewCountPosts,
    tt.TotalComments,
    tt.TotalBountyAmount,
    tt.Rank,
    CASE 
        WHEN tt.PostCount > 100 THEN 'High Activity'
        WHEN tt.PostCount BETWEEN 51 AND 100 THEN 'Moderate Activity'
        ELSE 'Low Activity' 
    END AS ActivityLevel
FROM 
    TopTags AS tt
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.Rank;