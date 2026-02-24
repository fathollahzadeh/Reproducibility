WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        TotalViews,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByTotalViews,
        RANK() OVER (ORDER BY UpVoteCount DESC) AS RankByUpVotes
    FROM 
        TagStats
)
SELECT 
    TagId,
    TagName,
    PostCount,
    TotalViews,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    RankByPostCount,
    RankByTotalViews,
    RankByUpVotes
FROM 
    TopTags
WHERE 
    RankByPostCount <= 10 OR 
    RankByTotalViews <= 10 OR 
    RankByUpVotes <= 10
ORDER BY 
    RankByPostCount, RankByTotalViews, RankByUpVotes;
