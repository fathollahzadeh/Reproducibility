WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1
),
UserVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v 
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName, 
    up.PostId, 
    up.Title, 
    up.CreationDate, 
    up.Score, 
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes, 
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes, 
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    ph.LastEditDate,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Users u
LEFT JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId AND up.rn = 1
LEFT JOIN 
    UserVotes uv ON up.PostId = uv.PostId
LEFT JOIN 
    PostHistoryStats ph ON up.PostId = ph.PostId
LEFT JOIN 
    Comments c ON up.PostId = c.PostId
WHERE 
    u.Reputation > 1000
    AND (up.Score IS NOT NULL OR up.CreationDate IS NULL)
GROUP BY 
    u.DisplayName, 
    up.PostId, 
    up.Title, 
    up.CreationDate, 
    up.Score, 
    uv.UpVotes, 
    uv.DownVotes, 
    ph.EditCount, 
    ph.LastEditDate
ORDER BY 
    TotalUpVotes DESC, 
    TotalDownVotes ASC
LIMIT 50;
