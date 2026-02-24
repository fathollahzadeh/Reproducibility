WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        ROW_NUMBER() OVER (ORDER BY Users.Reputation DESC) AS ReputationRank
    FROM Users
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.OwnerUserId,
        COUNT(Comments.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT CASE WHEN VoteTypes.Name = 'AcceptedByOriginator' THEN Votes.Id END) AS AcceptedVotes
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN VoteTypes ON Votes.VoteTypeId = VoteTypes.Id
    GROUP BY Posts.Id, Posts.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
FinalStatistics AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(p.CommentCount, 0) AS TotalComments,
        COALESCE(p.UpVoteCount, 0) AS TotalUpVotes,
        COALESCE(p.DownVoteCount, 0) AS TotalDownVotes,
        COALESCE(c.CloseCount, 0) AS TotalClosedPosts,
        ROW_NUMBER() OVER (PARTITION BY u.UserId ORDER BY COALESCE(p.CommentCount, 0) DESC) AS CommentsRank
    FROM UserReputation u
    LEFT JOIN PostStatistics p ON u.UserId = p.OwnerUserId
    LEFT JOIN ClosedPostStats c ON p.PostId = c.PostId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalClosedPosts,
    CommentsRank
FROM FinalStatistics
WHERE Reputation >= 100 
AND (TotalUpVotes > TotalDownVotes OR TotalClosedPosts > 0)
ORDER BY Reputation DESC, TotalUpVotes DESC;
