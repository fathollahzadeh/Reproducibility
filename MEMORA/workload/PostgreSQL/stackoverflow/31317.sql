WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
RecentActivePosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        PostRank,
        CommentCount,
        TotalBounty,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId 
         AND ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year') AS EditCount
    FROM 
        RankedPosts rp
    WHERE 
        PostRank = 1
),
SelectedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        CommentCount,
        TotalBounty,
        EditCount,
        CASE 
            WHEN TotalBounty > 0 THEN 'Has Bounty'
            ELSE 'No Bounty'
        END AS BountyStatus
    FROM 
        RecentActivePosts
    WHERE 
        Score > 10 OR CommentCount > 5
)
SELECT 
    sp.PostId,
    sp.Title,
    sp.Score,
    sp.CreationDate,
    sp.LastActivityDate,
    sp.OwnerDisplayName,
    sp.CommentCount,
    sp.TotalBounty,
    sp.EditCount,
    sp.BountyStatus,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = sp.PostId AND ph.PostHistoryTypeId IN (10, 11) 
            HAVING COUNT(*) > 0
        ) THEN 'Closed/Reopened'
        ELSE 'Open'
    END AS PostStatus
FROM 
    SelectedPosts sp
ORDER BY 
    sp.Score DESC, sp.LastActivityDate DESC
LIMIT 100;