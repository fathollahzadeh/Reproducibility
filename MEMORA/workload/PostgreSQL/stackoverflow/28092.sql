WITH TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        ARRAY_AGG(DISTINCT p.Title) AS PostTitles,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.TagName
), 
RankedTags AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        TagSummary
)
SELECT 
    TagName, 
    PostCount, 
    PostTitles, 
    TotalComments,
    TotalVotes,
    TotalViews,
    ViewRank,
    VoteRank
FROM 
    RankedTags
WHERE 
    ViewRank <= 10 OR VoteRank <= 10
ORDER BY 
    GREATEST(ViewRank, VoteRank);