WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS TotalUsers,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM Posts
),
UserStats AS (
    SELECT
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes
    FROM Users
),
VoteStats AS (
    SELECT
        COUNT(*) AS TotalVotes,
        COUNT(DISTINCT PostId) AS TotalPostVotes,
        AVG(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        AVG(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes
    FROM Votes
)

SELECT 
    p.TotalPosts,
    p.TotalUsers AS UniquePostOwners,
    p.AvgViewCount,
    p.AvgScore,
    u.TotalUsers AS UserCount,
    u.AvgReputation,
    u.AvgUpVotes AS UserAvgUpVotes,
    u.AvgDownVotes AS UserAvgDownVotes,
    v.TotalVotes,
    v.TotalPostVotes,
    v.AvgUpVotes AS VoteAvgUpVotes,
    v.AvgDownVotes AS VoteAvgDownVotes
FROM PostStats p
JOIN UserStats u ON 1=1
JOIN VoteStats v ON 1=1;