
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(ups.UpVotes, 0) AS UpVotes,
        COALESCE(downs.DownVotes, 0) AS DownVotes,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN (SELECT PostId, COUNT(*) AS UpVotes FROM Votes v JOIN VoteTypes vt ON v.VoteTypeId = vt.Id WHERE vt.Name = 'UpMod' GROUP BY PostId) ups ON p.Id = ups.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS DownVotes FROM Votes v JOIN VoteTypes vt ON v.VoteTypeId = vt.Id WHERE vt.Name = 'DownMod' GROUP BY PostId) downs ON p.Id = downs.PostId
)
SELECT 
    ud.UserId,
    ud.TotalVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.UpVotes AS PostUpVotes,
    pd.DownVotes AS PostDownVotes
FROM UserVoteSummary ud
JOIN PostDetails pd ON ud.UserId = pd.OwnerUserId
ORDER BY ud.TotalVotes DESC, pd.Score DESC
LIMIT 100;
