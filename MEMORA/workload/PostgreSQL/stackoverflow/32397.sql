
WITH RecursiveTagCounts AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%' )
    GROUP BY 
        Tags.Id, Tags.TagName
),
TopTags AS (
    SELECT 
        TagId, 
        TagName, 
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        RecursiveTagCounts
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalUpVotes,
        TotalDownVotes,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    u.DisplayName AS UserDisplayName,
    t.TagName AS TopTagName,
    t.PostCount AS TagPostCount,
    u.TotalPosts AS UserTotalPosts,
    u.TotalUpVotes,
    u.TotalDownVotes,
    u.TotalViews,
    u.TotalScore
FROM 
    TopUsers u
JOIN 
    TopTags t ON t.TagRank <= 5 
WHERE 
    u.TotalPosts > 0 
ORDER BY 
    u.TotalScore DESC, t.PostCount DESC;
