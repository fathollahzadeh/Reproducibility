WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS UserPostCount,
        SUM(CASE WHEN Posts.OwnerUserId IS NULL THEN 1 ELSE 0 END) AS CommunityPostCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    GROUP BY 
        Tags.TagName
),
TaggedPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Body,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        ARRAY_AGG(DISTINCT Tags.TagName) AS Tags
    FROM 
        Posts
    JOIN 
        Tags ON Posts.Tags LIKE '%' || Tags.TagName || '%'
    WHERE 
        Posts.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        Posts.Id
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT Posts.Id) AS TotalPostsCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Posts.OwnerUserId = Users.Id
    LEFT JOIN 
        Votes ON Votes.UserId = Users.Id AND Votes.PostId = Posts.Id
    GROUP BY 
        Users.Id, Users.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PostHistory.PostId,
        Count(PostHistory.Id) FILTER (WHERE PostHistory.PostHistoryTypeId IN (10, 11, 12, 13)) AS CloseOpenCount,
        Count(DISTINCT CASE WHEN PostHistory.PostHistoryTypeId IN (4, 5, 6) THEN PostHistory.Id END) AS EditCount
    FROM 
        PostHistory
    GROUP BY 
        PostHistory.PostId
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.UserPostCount,
    tc.CommunityPostCount,
    COUNT(DISTINCT tp.PostId) AS TotalTaggedPosts,
    AVG(pr.UpVotesCount - pr.DownVotesCount) AS AvgUserReputation,
    SUM(pq.CloseOpenCount) AS TotalCloseOpenActions,
    SUM(pq.EditCount) AS TotalEdits
FROM 
    TagCounts tc
LEFT JOIN 
    TaggedPosts tp ON tp.Tags @> ARRAY[tc.TagName]
LEFT JOIN 
    UserReputation pr ON pr.TotalPostsCount > 0
LEFT JOIN 
    PostHistorySummary pq ON pq.PostId = tp.PostId
GROUP BY 
    tc.TagName, tc.PostCount, tc.UserPostCount, tc.CommunityPostCount
ORDER BY 
    tc.PostCount DESC;