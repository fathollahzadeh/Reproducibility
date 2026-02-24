WITH UserReputation AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, UpVotes, DownVotes, (UpVotes - DownVotes) AS Score
    FROM Users
), RecentPosts AS (
    SELECT Id, Title, ViewCount, CreationDate, OwnerUserId, PostTypeId, AcceptedAnswerId
    FROM Posts
    WHERE CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), PostsWithOwners AS (
    SELECT rp.*, ur.DisplayName AS OwnerDisplayName
    FROM RecentPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.Id
), AcceptedAnswers AS (
    SELECT p.Id AS PostId, p.AcceptedAnswerId, a.Title AS AcceptedAnswerTitle
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1
), VotesCount AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
)
SELECT p.Title, p.OwnerDisplayName, p.ViewCount, p.CreationDate, 
       COALESCE(a.AcceptedAnswerTitle, 'N/A') AS AcceptedAnswerTitle,
       COALESCE(vc.Upvotes, 0) AS Upvotes, COALESCE(vc.Downvotes, 0) AS Downvotes
FROM PostsWithOwners p
LEFT JOIN AcceptedAnswers a ON p.Id = a.PostId
LEFT JOIN VotesCount vc ON p.Id = vc.PostId
ORDER BY p.ViewCount DESC, p.CreationDate DESC
LIMIT 50;