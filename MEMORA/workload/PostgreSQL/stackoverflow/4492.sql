WITH UserVoteStats AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes,
        COUNT(DISTINCT PostId) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostsWithVotes AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        u.DisplayName,
        COALESCE(uvs.UpVotes, 0) AS UpVotes,
        COALESCE(uvs.DownVotes, 0) AS DownVotes,
        COALESCE(uvs.AcceptedVotes, 0) AS AcceptedVotes
    FROM RecentPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN UserVoteStats uvs ON u.Id = uvs.UserId
    WHERE rp.PostRank = 1
)
SELECT 
    pwv.Title,
    pwv.CreationDate,
    pwv.DisplayName,
    pwv.UpVotes,
    pwv.DownVotes,
    pwv.AcceptedVotes,
    CASE 
        WHEN pwv.UpVotes - pwv.DownVotes > 10 THEN 'High Engagement'
        WHEN pwv.UpVotes - pwv.DownVotes BETWEEN 1 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM PostsWithVotes pwv
WHERE pwv.UpVotes IS NOT NULL OR pwv.DownVotes IS NOT NULL
ORDER BY pwv.CreationDate DESC
LIMIT 50;