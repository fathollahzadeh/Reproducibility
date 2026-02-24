
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    u.DisplayName,
    tu.TotalBounties,
    pt.TagName,
    pt.TagCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    COALESCE(CommentsCount.TotalComments, 0) AS TotalComments,
    COALESCE(ClosedPosts.TotalClosed, 0) AS TotalClosedPosts
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
LEFT JOIN (
    SELECT 
        PostId, COUNT(*) AS TotalComments
    FROM 
        Comments 
    GROUP BY 
        PostId
) AS CommentsCount ON CommentsCount.PostId = rp.PostId
LEFT JOIN (
    SELECT 
        p.Id AS ClosedPostId, COUNT(*) AS TotalClosed
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        ph.PostId IS NOT NULL
    GROUP BY 
        p.Id
) AS ClosedPosts ON ClosedPosts.ClosedPostId = rp.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
