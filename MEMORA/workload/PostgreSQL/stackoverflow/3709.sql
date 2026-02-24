
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentsCount,
        RANK() OVER (ORDER BY ps.Score DESC, ps.UpVotes DESC) AS ScoreRank
    FROM 
        PostStats ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.UpVotesCount,
    ups.DownVotesCount,
    ups.TotalBountySpent,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentsCount
FROM 
    UserVoteStats ups
CROSS JOIN 
    (SELECT PostId, Title, Score, UpVotes, DownVotes, CommentsCount FROM RankedPosts WHERE ScoreRank <= 10) rp
WHERE 
    ups.UpVotesCount > ups.DownVotesCount
    AND (ups.TotalBountySpent > 0 OR ups.UpVotesCount > 10)
ORDER BY 
    ups.DisplayName, rp.Score DESC;
