WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId AND c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100 OR COUNT(b.Id) >= 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
        AND ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostWithLinks AS (
    SELECT 
        p.Id AS PostId,
        pl.RelatedPostId,
        lt.Name AS LinkTypeName
    FROM 
        Posts p
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        lt.Name IS NOT NULL
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.BadgeCount,
    pld.PostHistoryTypeId,
    pld.ChangeRank,
    pwl.RelatedPostId,
    pwl.LinkTypeName,
    CASE 
        WHEN pld.PostHistoryTypeId IS NULL THEN 'No history available'
        ELSE 'History exists'
    END AS HistoryStatus
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId) 
LEFT JOIN 
    PostHistoryDetails pld ON rp.PostId = pld.PostId AND pld.ChangeRank = 1
LEFT JOIN 
    PostWithLinks pwl ON rp.PostId = pwl.PostId
WHERE 
    (rp.CommentCount > 5 OR rp.Score > 10)
    AND (rp.ViewCount IS NOT NULL OR rp.ViewCount > 100)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;