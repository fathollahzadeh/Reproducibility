
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.EditCount,
        ps.LastEdited,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        uvs.NetVotes AS UserNetVotes
    FROM Users u
    JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    JOIN UserVoteSummary uvs ON u.Id = uvs.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostId,
    ups.Title,
    ups.CommentCount,
    ups.EditCount,
    ups.LastEdited,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.UserNetVotes
FROM UserPostSummary ups
WHERE ups.UserNetVotes > 0
ORDER BY ups.UserNetVotes DESC, ups.TotalUpVotes DESC;
