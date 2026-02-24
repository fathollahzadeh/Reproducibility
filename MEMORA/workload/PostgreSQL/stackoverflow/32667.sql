
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        rp.PostRank,
        rp.CommentCount,
        rp.TotalBounty,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
        JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank = 1
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        p.LastActivityDate,
        p.LastEditorDisplayName,
        STRING_AGG(pt.Name, ', ') AS PostHistoryTypes
    FROM 
        Posts p
        INNER JOIN PostHistory ph ON p.Id = ph.PostId
        INNER JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 DAY'
    GROUP BY 
        p.Id, p.Title, ph.CreationDate, p.LastActivityDate, p.LastEditorDisplayName
)
SELECT 
    tp.PostId,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostCreationDate,
    tp.Score AS TopPostScore,
    tp.OwnerDisplayName,
    ra.Title AS RecentActivityTitle,
    ra.HistoryDate,
    ra.LastActivityDate,
    ra.LastEditorDisplayName,
    ra.PostHistoryTypes
FROM 
    TopPosts tp
FULL OUTER JOIN RecentActivity ra ON tp.PostId = ra.PostId
ORDER BY 
    tp.Score DESC, 
    ra.HistoryDate DESC;
