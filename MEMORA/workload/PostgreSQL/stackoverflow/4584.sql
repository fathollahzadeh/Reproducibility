
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)  
    GROUP BY 
        rp.PostId, rp.Title, rp.Score
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        UpVotes,
        DownVotes,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC, UpVotes DESC) AS PostRank
    FROM 
        PostAnalytics
    WHERE 
        Score > 0 OR CommentCount > 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    CASE 
        WHEN fp.PostRank <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    COALESCE(ph.UserDisplayName, 'Anonymous') AS LastEditor
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    (SELECT PostId, UserDisplayName FROM PostHistory WHERE PostHistoryTypeId = 24 ORDER BY CreationDate DESC) ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId IN (1, 2)  
ORDER BY 
    fp.PostRank;
