WITH TagUsage AS (
    SELECT 
        Tags.TagName, 
        COUNT(DISTINCT Posts.Id) AS PostCount, 
        SUM(LENGTH(Posts.Body) - LENGTH(REPLACE(Posts.Body, Tags.TagName, ''))) / LENGTH(Tags.TagName) AS TagMentionCount
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%' )
    GROUP BY 
        Tags.TagName
),
TopUsers AS (
    SELECT 
        Users.DisplayName, 
        SUM(Votes.BountyAmount) AS TotalBounties, 
        COUNT(DISTINCT Posts.Id) AS TotalPosts, 
        SUM(Posts.ViewCount) AS TotalViews
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Votes.UserId = Users.Id AND Votes.PostId = Posts.Id AND Votes.VoteTypeId = 9 
    WHERE 
        Users.Reputation > 1000
    GROUP BY 
        Users.DisplayName
),
PopularTags AS (
    SELECT 
        TagUsage.TagName, 
        TagUsage.PostCount, 
        TagUsage.TagMentionCount, 
        ROW_NUMBER() OVER (ORDER BY TagUsage.PostCount DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        TagUsage.PostCount > 10
)
SELECT 
    t.TagName, 
    t.PostCount, 
    t.TagMentionCount,
    u.DisplayName AS TopUser, 
    u.TotalBounties, 
    u.TotalPosts, 
    u.TotalViews
FROM 
    PopularTags t
JOIN 
    TopUsers u ON u.TotalPosts = (SELECT MAX(TotalPosts) FROM TopUsers)
ORDER BY 
    t.Rank
LIMIT 10;
