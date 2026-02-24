WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT ph.PostId) AS PostsEdited
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS UserComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    up.UserId,
    up.TotalBounties,
    up.Upvotes,
    up.Downvotes,
    up.PostsEdited,
    pt.TagName,
    ph.EditCount,
    ph.UserComments,
    CASE WHEN rp.Score > 100 THEN 'Hot' WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending' ELSE 'New' END AS PostStatus,
    CASE 
        WHEN ph.UserComments IS NULL THEN 'No Comments'
        ELSE 'Comments Present'
    END AS CommentStatus,
    CASE 
        WHEN up.TotalBounties IS NULL OR up.TotalBounties = 0 THEN 'No Bounties'
        ELSE CONCAT(up.TotalBounties, ' Bounty Points')
    END AS BountyStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity up ON up.UserId = rp.PostId  
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 10  
LEFT JOIN 
    PostHistories ph ON ph.PostId = rp.PostId
WHERE 
    rp.RN <= 5  
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;