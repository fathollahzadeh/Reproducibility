
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        pm.UpVotes,
        pm.DownVotes,
        CASE 
            WHEN pm.UserPostRank < 5 THEN 'Top Contributor' 
            ELSE 'Contributor' 
        END AS ContributorLevel
    FROM 
        PostMetrics pm
    WHERE 
        pm.ViewCount > 100
)
SELECT 
    pm.Title,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    COALESCE(pm.ContributorLevel, 'New Contributor') AS ContributorLevel
FROM 
    TopPosts pm
WHERE 
    pm.CommentCount > 0
AND 
    pm.UpVotes - pm.DownVotes >= 5
ORDER BY 
    pm.Score DESC
LIMIT 10;
