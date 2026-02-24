WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5
),
VoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.OwnerDisplayName, 
    COALESCE(vc.Upvotes, 0) AS Upvotes, 
    COALESCE(vc.Downvotes, 0) AS Downvotes, 
    COALESCE(vc.TotalBounty, 0) AS TotalBounty
FROM 
    TopPosts tp
LEFT JOIN 
    VoteCounts vc ON tp.PostId = vc.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;