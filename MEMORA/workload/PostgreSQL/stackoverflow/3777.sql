
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS ActivePosts
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
FinalResult AS (
    SELECT 
        uvs.DisplayName,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.TotalBounty,
        CASE 
            WHEN ps.CommentCount = 0 THEN 'No Comments' 
            ELSE 'Comments Available' 
        END AS CommentStatus,
        uvs.UpVotes,
        uvs.DownVotes,
        uvs.ActivePosts
    FROM UserVoteStats uvs
    JOIN PostStats ps ON uvs.UserId = ps.OwnerUserId
    WHERE uvs.ActivePosts > 5
)
SELECT
    FR.DisplayName,
    FR.Title,
    FR.CreationDate,
    FR.CommentCount,
    FR.TotalBounty,
    FR.CommentStatus,
    (FR.UpVotes - FR.DownVotes) AS NetVotes,
    CASE 
        WHEN FR.TotalBounty > 0 THEN 'Bounty Offered' 
        WHEN FR.CommentCount > 10 THEN 'Popular Discussion' 
        ELSE 'Standard Post' 
    END AS PostCategory
FROM FinalResult FR
ORDER BY FR.CreationDate DESC
LIMIT 100 OFFSET 0;
