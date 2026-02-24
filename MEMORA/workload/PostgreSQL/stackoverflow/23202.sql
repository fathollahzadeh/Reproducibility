WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT AVG(v.VoteTypeId) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
         GROUP BY v.PostId) AS AvgVoteType,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.OwnerUserId,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        CASE 
            WHEN rp.CommentCount = 0 THEN 'No Comments'
            WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Few Comments'
            ELSE 'Many Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.RN <= 10
),
RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.CommentStatus,
    rv.UpVotes,
    rv.DownVotes,
    CASE 
        WHEN rv.UpVotes - rv.DownVotes < 0 THEN 'Negative Engagement'
        WHEN rv.UpVotes > rv.DownVotes THEN 'Positive Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus
FROM 
    PostStatistics ps
JOIN 
    RecentVotes rv ON ps.PostId = rv.PostId
WHERE 
    ps.OwnerReputation IS NOT NULL
ORDER BY 
    ps.Score DESC, rv.UpVotes DESC
LIMIT 100;