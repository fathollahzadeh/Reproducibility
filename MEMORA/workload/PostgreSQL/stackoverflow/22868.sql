
WITH UserVoteCount AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        CASE WHEN pm.RankPerUser <= 3 THEN 'Top' ELSE 'Normal' END AS PostCategory
    FROM 
        PostMetrics pm
    LEFT JOIN 
        Users u ON u.Id = (SELECT AcceptedAnswerId FROM Posts WHERE Id = pm.PostId)
    WHERE 
        pm.Score > 10
), RecentActivity AS (
    SELECT 
        p.Id,
        MAX(ph.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)

SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.OwnerDisplayName,
    ra.LastActivityDate,
    CASE 
        WHEN uc.UpVotes IS NULL AND uc.DownVotes IS NULL THEN 0 
        ELSE COALESCE(uc.UpVotes, 0) - COALESCE(uc.DownVotes, 0)
    END AS NetVotes,
    CASE 
        WHEN tp.PostCategory = 'Top' THEN 'Highly Active'
        ELSE 'Regular Activity'
    END AS ActivityLevel
FROM 
    TopPosts tp
LEFT JOIN 
    UserVoteCount uc ON uc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    RecentActivity ra ON ra.Id = tp.PostId
WHERE 
    EXISTS (SELECT 1 
            FROM Comments c 
            WHERE c.PostId = tp.PostId AND c.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days'))
ORDER BY 
    tp.Score DESC, ra.LastActivityDate DESC
LIMIT 100;
