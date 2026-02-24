
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ue.UserId,
    ue.TotalVotes,
    ue.UpVotes,
    ue.DownVotes,
    ue.TotalBadges,
    CASE 
        WHEN ue.TotalVotes IS NULL THEN 'No votes'
        WHEN ue.UpVotes > ue.DownVotes THEN 'More Upvotes'
        ELSE 'More Downvotes'
    END AS VoteSummary
FROM 
    RankedPosts rp
INNER JOIN 
    UserEngagement ue ON ue.UserId = rp.PostId 
WHERE 
    rp.Rank <= 5
UNION ALL
SELECT 
    NULL, 
    'No Active Posts', 
    NULL, 
    NULL, 
    NULL, 
    ue.UserId,
    ue.TotalVotes,
    ue.UpVotes,
    ue.DownVotes,
    ue.TotalBadges,
    CASE 
        WHEN ue.TotalVotes IS NULL THEN 'No votes'
        WHEN ue.UpVotes > ue.DownVotes THEN 'More Upvotes'
        ELSE 'More Downvotes'
    END AS VoteSummary
FROM 
    UserEngagement ue
WHERE 
    NOT EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = ue.UserId)
ORDER BY 
    PostId DESC, 
    UserId DESC;
