
WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(*) AS TotalVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostEngagements AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 60) AS AvgResponseTime
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        pe.PostId,
        pe.CommentCount,
        pe.UpVotes,
        pe.DownVotes,
        pe.AvgResponseTime,
        RANK() OVER (ORDER BY pe.CommentCount DESC, pe.UpVotes DESC, pe.DownVotes ASC) AS PostRank
    FROM PostEngagements pe
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.PostId) AS EngagedPostCount,
    SUM(rp.UpVotes) AS TotalUpVotes,
    SUM(rp.DownVotes) AS TotalDownVotes,
    AVG(rp.AvgResponseTime) AS AvgPostResponseTime,
    CASE 
        WHEN COUNT(DISTINCT rp.PostId) > 5 THEN 'High Engager'
        WHEN COUNT(DISTINCT rp.PostId) BETWEEN 3 AND 5 THEN 'Medium Engager'
        ELSE 'Low Engager' 
    END AS EngagementLevel
FROM Users up
JOIN Votes v ON up.Id = v.UserId
JOIN RankedPosts rp ON v.PostId = rp.PostId
WHERE up.Reputation > 100 AND up.Location IS NOT NULL
GROUP BY up.DisplayName
HAVING SUM(rp.UpVotes) > (SELECT AVG(UpVoteCount) FROM UserVoteCounts uc) 
       AND COUNT(DISTINCT rp.PostId) > 1
ORDER BY TotalUpVotes DESC, EngagedPostCount DESC;
