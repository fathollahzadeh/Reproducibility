WITH TagCounts AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags AS tag
    JOIN 
        Posts AS p 
        ON p.Tags LIKE CONCAT('%<', tag.TagName, '> %')
    GROUP BY 
        tag.TagName
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users AS u
    JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        tc.TotalViews,
        tc.AverageScore,
        RANK() OVER (ORDER BY tc.PostCount DESC) AS Rank
    FROM 
        TagCounts AS tc
    WHERE 
        tc.PostCount > 5
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.PostsCount,
        ue.TotalViews,
        ue.UpVotes,
        ue.DownVotes,
        RANK() OVER (ORDER BY ue.TotalViews DESC) AS Rank
    FROM 
        UserEngagement AS ue
    WHERE 
        ue.PostsCount > 10
)
SELECT 
    t.Rank AS TagRank,
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AverageScore,
    u.Rank AS UserRank,
    u.DisplayName AS UserName,
    u.PostsCount AS UserPostsCount,
    u.TotalViews AS UserTotalViews,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes
FROM 
    TopTags AS t
JOIN 
    TopUsers AS u ON t.TotalViews = u.TotalViews
ORDER BY 
    TagRank, UserRank;
