
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
        AND p.PostTypeId = 1  
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS NumberOfPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month' 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.ViewCount) > 1000  
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
UnionedPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Viewed'
        ELSE 'Other'
    END AS RankDescription,
    pu.DisplayName,
    pu.TotalViews,
    cp.UserId AS CloseByUserId,
    COALESCE(cp.Comment, 'No Comment') AS CloseComment,
    COUNT(DISTINCT upl.RelatedPostId) AS RelatedLinks,
    STRING_AGG(upl.LinkType, ', ') AS LinkTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularUsers pu ON rp.OwnerUserId = pu.UserId
LEFT JOIN 
    ClosedPostHistory cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UnionedPostLinks upl ON rp.PostId = upl.PostId
WHERE 
    rp.ViewCount > 10  
GROUP BY 
    rp.Title, rp.ViewCount, pu.DisplayName, pu.TotalViews, cp.UserId, cp.Comment, rp.PostRank
ORDER BY 
    rp.ViewCount DESC;
