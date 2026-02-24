
WITH TagData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        STRING_AGG(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), ',') AS TagList,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Tags
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(TagList, ',')) AS TagName,
        COUNT(PostId) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        TagData
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalUpVotes DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    PostCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    TopTags
WHERE 
    Rank <= 10 
ORDER BY 
    TotalUpVotes DESC;
