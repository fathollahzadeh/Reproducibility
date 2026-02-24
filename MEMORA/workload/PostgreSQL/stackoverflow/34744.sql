
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 
),

PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AcceptedAnswerId,
        rp.Score,
        rp.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1 
),

PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagUsage
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    pt.TagName,
    pt.TagUsage
FROM 
    PostStats ps
LEFT JOIN 
    PopularTags pt ON ps.Title LIKE CONCAT('%', pt.TagName, '%') 
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
