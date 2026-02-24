
WITH UserReputation AS (
    SELECT Users.Id, Users.Reputation, COUNT(DISTINCT Posts.Id) AS PostCount, 
           SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
           SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Users.Id, Users.Reputation
),
PostDetails AS (
    SELECT Posts.Id AS PostId, Posts.Title, Posts.CreationDate, Posts.Score, 
           Users.DisplayName AS OwnerName, PostTypes.Name AS PostType, 
           COUNT(Comments.Id) AS CommentCount, 
           COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes, 
           COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM Posts
    LEFT JOIN Users ON Posts.OwnerUserId = Users.Id
    LEFT JOIN PostTypes ON Posts.PostTypeId = PostTypes.Id
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Posts.Id, Posts.Title, Posts.CreationDate, Posts.Score, Users.DisplayName, PostTypes.Name
),
TopUsers AS (
    SELECT UserReputation.Id, UserReputation.Reputation, UserReputation.PostCount, 
           UserReputation.Upvotes, UserReputation.Downvotes
    FROM UserReputation
    WHERE UserReputation.Reputation > (SELECT AVG(Reputation) FROM Users)
    ORDER BY UserReputation.Reputation DESC
    LIMIT 10
)
SELECT 
    TopUsers.Id AS UserId,
    TopUsers.Reputation,
    PostDetails.Title,
    PostDetails.CreationDate,
    PostDetails.Score,
    PostDetails.CommentCount,
    PostDetails.TotalUpvotes,
    PostDetails.TotalDownvotes
FROM TopUsers
JOIN Posts ON TopUsers.Id = Posts.OwnerUserId
JOIN PostDetails ON Posts.Id = PostDetails.PostId
ORDER BY TopUsers.Reputation DESC, PostDetails.Score DESC;
