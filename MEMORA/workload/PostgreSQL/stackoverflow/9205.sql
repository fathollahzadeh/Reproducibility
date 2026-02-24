
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC) AS Rank
    FROM PostStats ps
    WHERE ps.CloseCount = 0 
),
TopUsers AS (
    SELECT 
        uvs.*,
        RANK() OVER (ORDER BY uvs.TotalVotes DESC) AS VoteRank
    FROM UserVoteStats uvs
)
SELECT 
    tu.DisplayName AS TopVoter,
    tu.UpVotes AS UpVotes,
    tu.DownVotes AS DownVotes,
    tp.Title AS TopPostTitle,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViewCount
FROM TopUsers tu
INNER JOIN TopPosts tp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE tu.VoteRank <= 10 AND tp.Rank <= 10
ORDER BY tu.UpVotes DESC, tp.Score DESC;
