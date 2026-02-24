
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName
),
TopLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId, pl.RelatedPostId, lt.Name
    HAVING 
        COUNT(*) > 1 
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment = crt.Id::text
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    ad.TotalPosts,
    ad.PositivePosts,
    ad.NegativePosts,
    ad.TotalBountyAmount,
    tl.LinkCount,
    cr.Reasons AS CloseReasons
FROM 
    RankedPosts p
JOIN 
    AggregatedData ad ON p.PostId = ad.UserId
LEFT JOIN 
    TopLinks tl ON p.PostId = tl.PostId
LEFT JOIN 
    CloseReasons cr ON p.PostId = cr.PostId
WHERE 
    (p.Rank <= 5 OR cr.CloseReasonCount > 0) 
ORDER BY 
    p.Score DESC, ad.TotalPosts DESC;
