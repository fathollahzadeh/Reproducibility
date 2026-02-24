
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score,
        COUNT(c.Id) AS CommentCount,
        u.DisplayName AS OwnerName,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedPost
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
), 
PostStatistics AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.CommentCount,
        CASE 
            WHEN rp.AcceptedPost IS NOT NULL THEN 'Accepted Answer'
            ELSE 'No Accepted Answer' 
        END AS AcceptanceStatus,
        RANK() OVER (ORDER BY rp.Score DESC) AS PostRank
    FROM 
        RecentPosts rp
)
SELECT 
    ur.DisplayName AS UserDisplayName, 
    ur.Reputation, 
    ps.Title, 
    ps.CreationDate,
    ps.Score,
    ps.CommentCount, 
    ps.AcceptanceStatus
FROM 
    UserReputation ur
LEFT JOIN 
    Posts p ON ur.UserId = p.OwnerUserId
LEFT JOIN 
    PostStatistics ps ON p.Id = ps.PostId
WHERE 
    ur.Rank <= 10 
    AND (ps.Score IS NOT NULL OR ps.CommentCount > 0)
ORDER BY 
    ur.Reputation DESC, ps.Score DESC;
