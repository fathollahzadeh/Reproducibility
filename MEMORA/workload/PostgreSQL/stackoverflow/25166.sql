
WITH RankedTags AS (
    SELECT 
        Tags.TagName, 
        COUNT(*) AS TagCount 
    FROM 
        Posts 
    JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')) AS TagName) AS Tags ON true 
    WHERE 
        Posts.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        Tags.TagName 
    HAVING 
        COUNT(*) > 5
),
PopularPosts AS (
    SELECT 
        Posts.Id, 
        Posts.Title, 
        Posts.Score, 
        Posts.ViewCount, 
        Posts.CreationDate, 
        ARRAY_AGG(Tags.TagName) AS PostTags 
    FROM 
        Posts 
    JOIN 
        LATERAL (SELECT unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')) AS TagName) AS Tags ON true 
    WHERE 
        Posts.PostTypeId = 1 
        AND Posts.Score > 10 
    GROUP BY 
        Posts.Id, Posts.Title, Posts.Score, Posts.ViewCount, Posts.CreationDate 
    ORDER BY 
        Posts.ViewCount DESC 
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName, 
        COUNT(Votes.Id) AS VoteCount, 
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users 
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId 
    GROUP BY 
        Users.Id, Users.DisplayName 
    HAVING 
        COUNT(Votes.Id) > 0
),
PostInsights AS (
    SELECT 
        Posts.Id AS PostId, 
        Posts.Title, 
        Posts.ViewCount, 
        Users.DisplayName AS OwnerName, 
        COALESCE(RankedTags.TagCount, 0) AS Popularity, 
        COALESCE(UserEngagement.VoteCount, 0) AS UserVoteCount 
    FROM 
        Posts 
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id 
    LEFT JOIN 
        RankedTags ON RankedTags.TagName = ANY(string_to_array(Posts.Tags, '>')) 
    LEFT JOIN 
        UserEngagement ON UserEngagement.UserId = Posts.OwnerUserId 
    WHERE 
        Posts.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT 
    PostInsights.*, 
    PopularPosts.PostTags 
FROM 
    PostInsights 
LEFT JOIN 
    PopularPosts ON PostInsights.PostId = PopularPosts.Id 
ORDER BY 
    PostInsights.Popularity DESC, 
    PostInsights.UserVoteCount DESC 
LIMIT 15;
