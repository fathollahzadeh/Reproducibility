WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

TagsWithPosts AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS RelatedPostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
    HAVING 
        COUNT(p.Id) > 0
),

BountyPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.VoteTypeId IN (8, 9)  
    GROUP BY 
        p.Id, p.Title
    HAVING 
        SUM(v.BountyAmount) > 0
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.TotalBounty,
        rp.PostCategory,
        CASE 
            WHEN rp.RankScore <= 10 THEN 'Top Posts'
            ELSE 'Others'
        END AS RankingCategory,
        COALESCE(bp.TotalBounties, 0) AS TotalBounties
    FROM 
        RankedPosts rp
    LEFT JOIN 
        BountyPosts bp ON rp.PostId = bp.Id
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.TotalBounty,
    fp.PostCategory,
    fp.RankingCategory,
    CASE 
        WHEN fp.CommentCount > 10 THEN 'Highly Discussed'
        WHEN fp.TotalBounties > 0 THEN 'Bounty Offered'
        ELSE 'Regular'
    END AS PostStatus
FROM 
    FilteredPosts fp
ORDER BY 
    CASE 
        WHEN fp.RankingCategory = 'Top Posts' THEN 1
        ELSE 2
    END,
    fp.Score DESC,
    fp.TotalBounties DESC;