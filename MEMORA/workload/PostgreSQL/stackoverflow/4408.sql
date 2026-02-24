WITH UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId IN (2, 8) THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM Votes
    GROUP BY UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.AcceptedAnswerId END) AS AcceptedAnswerCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes vote ON p.Id = vote.PostId
    WHERE p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
PostMetrics AS (
    SELECT 
        rp.*,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COALESCE(uv.UpVotesCount, 0) AS UserUpVotesCount,
        COALESCE(uv.DownVotesCount, 0) AS UserDownVotesCount
    FROM RecentPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN UserVoteCounts uv ON rp.OwnerUserId = uv.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.OwnerReputation,
    pm.CommentCount,
    pm.TotalUpVotes,
    pm.TotalDownVotes,
    pm.AcceptedAnswerCount,
    CASE 
        WHEN pm.TotalUpVotes > pm.TotalDownVotes THEN 'Positive'
        WHEN pm.TotalUpVotes < pm.TotalDownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN pm.AcceptedAnswerCount > 0 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus
FROM PostMetrics pm
WHERE pm.OwnerReputation > 100
ORDER BY pm.TotalUpVotes DESC, pm.CommentCount DESC
LIMIT 50;