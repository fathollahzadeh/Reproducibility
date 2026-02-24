WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score IS NOT NULL
), 
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), 
UserScores AS (
    SELECT 
        u.Id AS UserId, 
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes
    FROM 
        Users u
    GROUP BY 
        u.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)

SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(us.NetVotes, 0) AS UserNetVotes,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserScores us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC;