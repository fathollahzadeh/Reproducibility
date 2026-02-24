WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' AND
        p.PostTypeId IN (1, 2) 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId,
        p.Title AS PostTitle,
        STRING_AGG(DISTINCT COALESCE(u.DisplayName, 'Anonymous'), ', ') AS Editors
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate > (SELECT MIN(CreationDate) FROM Posts) 
    GROUP BY 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate, 
        ph.UserId, 
        p.Title
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        phd.HistoryDate,
        phd.Editors,
        rp.CommentCount,
        rp.TotalBounty,
        CASE 
            WHEN rp.ViewCount IS NULL THEN 'No Views'
            WHEN rp.ViewCount > 1000 THEN 'Popular'
            ELSE 'Normal'
        END AS PopularityStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
    WHERE 
        rp.CommentCount > 0 
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerUserId,
    ps.Score,
    ps.ViewCount,
    ps.PopularityStatus,
    Coalesce(ps.Editors, 'No Edits Made') AS Editors,
    CASE 
        WHEN ps.TotalBounty > 0 THEN 'Offers Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM 
    PostSummary ps
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 100;