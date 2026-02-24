
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
        AND p.ViewCount IS NOT NULL
),
PostScore AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostTypeId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.PostTypeId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS VersionCount,
        STRING_AGG(CONCAT(CAST(ph.CreationDate AS DATE), ' ', ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
    HAVING 
        COUNT(*) > 1
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.TotalBounty,
        ps.TotalUpvotes,
        ps.TotalDownvotes,
        COALESCE(pht.VersionCount, 0) AS EditVersionCount,
        COALESCE(pht.EditComments, 'No edits') AS EditComments
    FROM 
        PostScore ps
    LEFT JOIN 
        PostHistoryDetails pht ON ps.PostId = pht.PostId
    WHERE 
        ps.PostTypeId IN (1, 2) 
)

SELECT 
    fr.*,
    CASE 
        WHEN fr.EditVersionCount > 0 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    (fr.TotalUpvotes - fr.TotalDownvotes) AS NetVotes,
    CASE 
        WHEN fr.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.TotalUpvotes DESC,
    fr.CreationDate DESC
LIMIT 10;
