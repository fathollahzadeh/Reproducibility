
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PostActivityStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY p.Id, p.Title
),
FinalStats AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        p.PostId,
        p.Title,
        us.TotalVotes AS UserTotalVotes,
        ps.TotalVotes AS PostTotalVotes,
        ps.TotalComments,
        ps.UpVotes AS PostUpVotes,
        ps.DownVotes AS PostDownVotes
    FROM UserVoteStats u
    JOIN PostActivityStats p ON u.UserId = p.PostId
    JOIN UserVoteStats us ON u.UserId = us.UserId
    JOIN PostActivityStats ps ON p.PostId = ps.PostId
)
SELECT 
    fs.DisplayName,
    fs.Title,
    fs.UserTotalVotes,
    fs.PostTotalVotes,
    fs.TotalComments,
    fs.PostUpVotes,
    fs.PostDownVotes
FROM FinalStats fs
ORDER BY fs.UserTotalVotes DESC, fs.PostTotalVotes DESC;
