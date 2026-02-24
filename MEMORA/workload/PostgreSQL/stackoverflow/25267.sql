WITH TagCounts AS (
    SELECT 
        Tags.TagName, 
        COUNT(DISTINCT Posts.Id) AS PostCount
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
PopularPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.ViewCount,
        Posts.CreationDate,
        Users.DisplayName AS Author,
        COALESCE(CommentsCount.CommentCount, 0) AS Comments,
        COALESCE(VotesCount.UpVotes, 0) AS UpVotes
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount
         FROM Comments
         GROUP BY PostId) AS CommentsCount ON CommentsCount.PostId = Posts.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVotes
         FROM Votes WHERE VoteTypeId = 2
         GROUP BY PostId) AS VotesCount ON VotesCount.PostId = Posts.Id
    WHERE 
        Posts.PostTypeId = 1  
    ORDER BY 
        Posts.ViewCount DESC
    LIMIT 10
),
ActiveUsers AS (
    SELECT 
        Users.Id,
        Users.DisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    GROUP BY 
        Users.Id, Users.DisplayName
)
SELECT 
    tc.TagName,
    pc.Title AS PopularPostTitle,
    pc.ViewCount AS PopularPostViews,
    pc.Author AS PopularPostAuthor,
    au.DisplayName AS ActiveUserName,
    au.UpVotes AS ActiveUserUpVotes,
    au.DownVotes AS ActiveUserDownVotes
FROM 
    TagCounts tc
JOIN 
    Posts p ON p.Tags LIKE '%' || tc.TagName || '%'
JOIN 
    PopularPosts pc ON pc.PostId = p.Id
JOIN 
    ActiveUsers au ON au.UpVotes > 0
ORDER BY 
    tc.PostCount DESC, pc.ViewCount DESC, au.UpVotes DESC;