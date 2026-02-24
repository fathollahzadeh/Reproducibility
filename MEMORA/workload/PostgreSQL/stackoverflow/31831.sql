
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, pt.Name
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserContribution AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id
),
EnhancedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Rank,
        phs.RevisionCount,
        phs.LastRevisionDate,
        uc.TotalBounty,
        uc.PostsCreated
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    LEFT JOIN 
        UserContribution uc ON rp.PostId = uc.UserId
)
SELECT 
    ep.Title,
    ep.Score,
    ep.ViewCount,
    ep.Rank,
    ep.RevisionCount,
    ep.LastRevisionDate,
    CASE 
        WHEN ep.TotalBounty > 0 THEN 'Active Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    ep.PostsCreated
FROM 
    EnhancedPosts ep
WHERE 
    ep.Rank <= 5
    AND ep.RevisionCount > 0
ORDER BY 
    ep.Score DESC, ep.ViewCount DESC;
