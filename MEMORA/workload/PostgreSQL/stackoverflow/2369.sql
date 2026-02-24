
WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC, ps.CreationDate ASC) AS PostRank
    FROM PostStats ps
)
SELECT 
    rp.Title,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpVotes IS NULL THEN 'No Votes Yet'
        WHEN rp.UpVotes = 0 THEN 'Neutral'
        ELSE 'Vote Difference: ' || (rp.UpVotes - rp.DownVotes)
    END AS VoteStatus,
    (SELECT COUNT(DISTINCT v.UserId) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 3)) AS UniqueVoterCount
FROM RankedPosts rp
WHERE rp.PostRank <= 10
ORDER BY rp.PostRank;
