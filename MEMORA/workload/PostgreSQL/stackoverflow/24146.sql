WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    r.CommentCount,
    au.DisplayName AS ActiveUserName,
    au.PostCount,
    (au.UpVotes - au.DownVotes) AS NetVotes,
    CASE 
        WHEN r.Score > 0 THEN 'Popular'
        WHEN r.Score < 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS PostType,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = r.PostId 
       AND ph.PostHistoryTypeId IN (10, 11, 12)
       AND ph.CreationDate >= r.CreationDate) AS CloseReopenCount
FROM 
    RecentActivity r
LEFT JOIN 
    ActiveUsers au ON r.OwnerDisplayName = au.DisplayName
WHERE 
    r.rn = 1
ORDER BY 
    r.CreationDate DESC,
    COALESCE(au.PostCount, 0) DESC,
    r.Score DESC
FETCH FIRST 50 ROWS ONLY;