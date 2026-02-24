WITH PostVoteAggregates AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.PostTypeId,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        COUNT(DISTINCT PostHistory.Id) AS EditCount
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    WHERE 
        Posts.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.PostTypeId
),
UserAggregates AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(PostVoteAggregates.UpVotes) AS TotalUpVotes,
        SUM(PostVoteAggregates.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT Posts.Id) AS PostsCount
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        PostVoteAggregates ON Posts.Id = PostVoteAggregates.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
)
SELECT 
    UserAggregates.DisplayName,
    UserAggregates.PostsCount,
    UserAggregates.TotalViews,
    UserAggregates.TotalUpVotes,
    UserAggregates.TotalDownVotes,
    CASE 
        WHEN UserAggregates.PostsCount = 0 THEN 0
        ELSE (UserAggregates.TotalUpVotes * 1.0 / UserAggregates.PostsCount)
    END AS AverageUpVotesPerPost,
    CASE 
        WHEN UserAggregates.PostsCount = 0 THEN 0
        ELSE (UserAggregates.TotalDownVotes * 1.0 / UserAggregates.PostsCount)
    END AS AverageDownVotesPerPost
FROM 
    UserAggregates
ORDER BY 
    UserAggregates.TotalViews DESC
LIMIT 10;