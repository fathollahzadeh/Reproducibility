WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 100
),
RecentComments AS (
    SELECT 
        c.PostId, 
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM Comments c
    GROUP BY c.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    COALESCE(rc.CommentCount, 0) AS TotalComments,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN rp.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAge,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM RankedPosts rp
LEFT JOIN RecentComments rc ON rp.Id = rc.PostId
LEFT JOIN PostVoteSummary ps ON rp.Id = ps.PostId
WHERE rp.PostRank <= 3
ORDER BY PostAge DESC, TotalUpVotes DESC;