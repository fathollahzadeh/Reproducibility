WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, UpVotes, DownVotes,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) as Rank
    FROM Users
    WHERE Reputation > 0
),
PopularTags AS (
    SELECT TagName, COUNT(*) AS PostCount
    FROM Tags
    JOIN Posts ON Posts.Tags LIKE CONCAT('%<', Tags.TagName, '>%' )
    GROUP BY TagName
    HAVING COUNT(*) > 10
),
RecentPosts AS (
    SELECT Posts.Id, Posts.Title, Posts.CreationDate, Posts.ViewCount, Posts.Score,
           (SELECT COUNT(*) FROM Comments WHERE PostId = Posts.Id) as CommentCount
    FROM Posts
    WHERE Posts.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostScoreWithVotes AS (
    SELECT P.Id, P.Title, P.Score, P.ViewCount, 
           COALESCE(VUp.UpVoteCount, 0) as UpVotes,
           COALESCE(VDown.DownVoteCount, 0) as DownVotes
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) as UpVoteCount
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) VUp ON VUp.PostId = P.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) as DownVoteCount
        FROM Votes
        WHERE VoteTypeId = 3
        GROUP BY PostId
    ) VDown ON VDown.PostId = P.Id
),
JoinedData AS (
    SELECT U.DisplayName, U.Reputation, P.Title, P.CreationDate, P.ViewCount, 
           P.Score, P.CommentCount, Tag.TagName,
           (U.UpVotes - U.DownVotes) AS NetVotes
    FROM UserReputationCTE U
    JOIN RecentPosts P ON P.Id = (SELECT Id FROM Posts WHERE OwnerUserId = U.Id LIMIT 1)
    LEFT JOIN PopularTags Tag ON P.Title LIKE '%' || Tag.TagName || '%'
)
SELECT JD.DisplayName, JD.Reputation, JD.Title, JD.CreationDate,
       JD.ViewCount, JD.Score, JD.CommentCount, JD.TagName,
       JD.NetVotes, 
       CASE 
           WHEN JD.NetVotes > 0 THEN 'Positive' 
           WHEN JD.NetVotes < 0 THEN 'Negative' 
           ELSE 'Neutral' 
       END AS VoteStatus
FROM JoinedData JD
WHERE JD.Reputation > 100
ORDER BY JD.Reputation DESC, JD.ViewCount DESC
LIMIT 50;