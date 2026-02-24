
WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '>')) AS Tag,
        Posts.Id AS PostId,
        Posts.Title,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        AVG(Users.Reputation) AS AvgUserReputation
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Posts.Id, Posts.Title, Tag
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(PostId) AS UsageCount
    FROM 
        TagUsage
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
TagStats AS (
    SELECT 
        tu.Tag,
        AVG(tu.CommentCount) AS AvgComments,
        SUM(tu.UpvoteCount) AS TotalUpvotes,
        SUM(tu.DownvoteCount) AS TotalDownvotes,
        AVG(tu.AvgUserReputation) AS AvgReputation
    FROM 
        TagUsage tu
    JOIN 
        PopularTags pt ON tu.Tag = pt.Tag
    GROUP BY 
        tu.Tag
)
SELECT 
    ts.Tag,
    ts.AvgComments,
    ts.TotalUpvotes,
    ts.TotalDownvotes,
    ts.AvgReputation,
    CASE 
        WHEN ts.TotalUpvotes > ts.TotalDownvotes THEN 'Positive'
        WHEN ts.TotalUpvotes < ts.TotalDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TagStats ts
ORDER BY 
    ts.TotalUpvotes DESC, ts.TotalDownvotes ASC;
