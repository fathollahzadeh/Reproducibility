
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(ph.Comment, ', ') AS CloseComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        ue.UserId, 
        ue.DisplayName,
        ue.PostCount,
        ue.CommentScore,
        ue.TotalBounty,
        COALESCE(cp.CloseReasonCount, 0) AS CloseCount,
        COALESCE(cp.LastClosedDate, NULL) AS LastClosed,
        COALESCE(cp.CloseComments, 'No recent closures') AS RecentCloseReasons
    FROM 
        UserEngagement ue
    LEFT JOIN 
        ClosedPostStats cp ON ue.PostCount > 0 AND ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.PostCount,
    fr.CommentScore,
    fr.TotalBounty,
    fr.CloseCount,
    fr.LastClosed,
    fr.RecentCloseReasons,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount
FROM 
    FinalReport fr
LEFT JOIN 
    RankedPosts rp ON fr.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    fr.PostCount > 5 
ORDER BY 
    fr.CommentScore DESC, fr.TotalBounty DESC;
