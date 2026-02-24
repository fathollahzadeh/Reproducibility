
WITH UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS PostsCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT Posts.Id) DESC) AS ActivityRank
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    WHERE 
        Users.Reputation > 1000
    GROUP BY 
        Users.Id, Users.DisplayName
),

ClosedPosts AS (
    SELECT 
        Posts.Id,
        Posts.Title,
        COUNT(PostHistory.Id) AS CloseActions,
        MAX(PostHistory.CreationDate) AS LastClosed
    FROM 
        Posts
    INNER JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId 
    WHERE 
        PostHistory.PostHistoryTypeId = 10
    GROUP BY 
        Posts.Id, Posts.Title
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostsCount,
    UA.UpVotes,
    UA.DownVotes,
    UA.ActivityRank,
    COALESCE(CP.CloseActions, 0) AS TotalCloseActions,
    CP.LastClosed
FROM 
    UserActivity UA
LEFT JOIN 
    ClosedPosts CP ON UA.UserId = (SELECT Posts.OwnerUserId FROM Posts WHERE Posts.Id = CP.Id)
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.ActivityRank;
