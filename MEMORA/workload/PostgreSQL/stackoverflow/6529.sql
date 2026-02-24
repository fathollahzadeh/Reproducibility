WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 AND (rp.UpVotes - rp.DownVotes) > 0
)
SELECT 
    fp.*, 
    COUNT(b.Id) AS BadgeCount,
    SUM(CASE WHEN bh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON fp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    PostHistory bh ON fp.PostId = bh.PostId
LEFT JOIN 
    PostTypes pt ON (SELECT PostTypeId FROM Posts WHERE Id = fp.PostId) = pt.Id
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.OwnerDisplayName, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC, fp.CreationDate DESC
LIMIT 100;