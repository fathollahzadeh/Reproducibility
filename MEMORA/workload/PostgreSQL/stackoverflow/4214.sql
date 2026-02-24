WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
PostStats AS (
    SELECT 
        p.Id,
        COUNT(cm.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments cm ON p.Id = cm.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        r.OwnerDisplayName,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        RankedPosts r ON p.Id = r.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    PostStats ps ON rp.Id = ps.Id
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
