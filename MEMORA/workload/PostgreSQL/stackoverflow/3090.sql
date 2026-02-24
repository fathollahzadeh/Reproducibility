WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
RecentActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate IS NOT NULL
)
SELECT 
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(rap.ViewCount, 0) AS ViewCount,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    rp.UpVotes,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Post'
        ELSE 'Previous Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    RecentActivePosts rap ON rp.Id = rap.Id
WHERE 
    u.Reputation > 1000
    AND rap.ActivityRank <= 10
ORDER BY 
    rp.UpVotes DESC,
    rp.CreationDate DESC
LIMIT 50;
