WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END) AS OffensiveCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    WHERE u.CreationDate >= '2023-01-01'
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.CommentCount,
    pe.UniqueVoterCount,
    pe.UpVoteCount,
    pe.DownVoteCount,
    pe.OffensiveCount,
    ue.UserId,
    ue.DisplayName,
    ue.PostCount,
    ue.CommentCount AS UserCommentCount,
    ue.TotalUpVotes,
    ue.TotalDownVotes
FROM PostEngagement pe
JOIN UserEngagement ue ON pe.UniqueVoterCount > 0 
ORDER BY pe.CreationDate DESC, pe.UpVoteCount DESC;