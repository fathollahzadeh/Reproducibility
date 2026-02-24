
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.ViewCount DESC) AS PopularityRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostType,
        rp.CreationDate,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.PopularityRank,
        p2.Title AS RelatedPostTitle
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostLinks pl ON rp.PostId = pl.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    WHERE 
        rp.PopularityRank <= 10
),
UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class IN (1, 2)
    GROUP BY 
        UserId
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostType,
    rp.CreationDate,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
    COALESCE(upc.PostCount, 0) AS PostCount,
    CASE 
        WHEN rp.Downvotes > rp.Upvotes THEN 'Needs Improvement'
        WHEN rp.Upvotes >= 10 THEN 'Popular Post'
        ELSE 'Moderately Accepted'
    END AS PostStatus,
    COALESCE(rp.RelatedPostTitle, 'No Related Posts') AS RelatedPostTitle
FROM 
    FilteredPosts rp
LEFT JOIN 
    UserBadgeCounts ubc ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ubc.UserId)
LEFT JOIN 
    UserPostCounts upc ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = upc.UserId)
ORDER BY 
    rp.Upvotes DESC, rp.ViewCount DESC;
