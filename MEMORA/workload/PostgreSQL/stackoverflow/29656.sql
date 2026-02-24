
WITH PopularTags AS (
    SELECT 
        T.TagName,
        T.Count, 
        P.Title,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' AND P.PostTypeId = 1
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        T.TagName, T.Count, P.Title
),
TopTags AS (
    SELECT 
        TagName,
        SUM(CommentCount) AS TotalComments,
        SUM(Upvotes) AS TotalUpvotes,
        SUM(Downvotes) AS TotalDownvotes,
        COUNT(DISTINCT Title) AS PostCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT Title) > 5
    ORDER BY 
        TotalUpvotes DESC
    LIMIT 10
)
SELECT 
    TT.TagName, 
    TT.TotalComments, 
    TT.TotalUpvotes, 
    TT.TotalDownvotes, 
    TT.PostCount,
    ROUND((TotalUpvotes::FLOAT / NULLIF(PostCount, 0)) * 100, 2) AS UpvotePercentage
FROM 
    TopTags TT
ORDER BY 
    UpvotePercentage DESC;
