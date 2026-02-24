WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Rank,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TotalBounties
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
        AND rp.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
),
PostClosureDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.TotalBounties,
    COALESCE(pcd.CloseReasons, 'Open') AS CloseReasons
FROM 
    FilteredPosts fp
    LEFT JOIN PostClosureDetails pcd ON fp.PostId = pcd.PostId
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;