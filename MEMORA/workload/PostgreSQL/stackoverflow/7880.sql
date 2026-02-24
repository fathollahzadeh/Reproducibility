WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven, 
        COUNT(c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesEarned,
        MAX(p.CreationDate) AS LastActivity
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
), 
VoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostSummary AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        COALESCE(vc.UpVotes, 0) AS TotalUpVotes, 
        COALESCE(vc.DownVotes, 0) AS TotalDownVotes,
        ua.DisplayName AS Author,
        ua.QuestionsAsked,
        ua.AnswersGiven,
        ua.CommentsMade,
        ua.BadgesEarned,
        ua.LastActivity
    FROM Posts p
    LEFT JOIN UserActivity ua ON p.OwnerUserId = ua.UserId
    LEFT JOIN VoteCounts vc ON p.Id = vc.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.Author,
    ps.QuestionsAsked,
    ps.AnswersGiven,
    ps.CommentsMade,
    ps.BadgesEarned,
    ps.LastActivity
FROM PostSummary ps
ORDER BY ps.ViewCount DESC, ps.TotalUpVotes DESC
LIMIT 50;