
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        FIRST_VALUE(p.Body) OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS LatestBody
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = cr.Id::varchar
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.ExcerptPostId = p.Id
    GROUP BY 
        t.TagName
    HAVING 
        SUM(p.ViewCount) > 10000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    tu.DisplayName,
    tu.Reputation,
    COALESCE(cp.CloseReasons, '{}') AS CloseReasonList,
    pt.TagName,
    pt.TotalViews
FROM 
    RecentPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.LatestBody, ' '))
WHERE 
    rp.Score > 5
    AND rp.CommentCount > 5
ORDER BY 
    rp.ViewCount DESC,
    rp.Score DESC
LIMIT 50;
