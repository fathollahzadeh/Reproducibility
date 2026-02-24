WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Tags,
        rp.PostType,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.Tags,
        tp.PostType,
        tp.OwnerDisplayName,
        pc.Comments,
        pb.Badges
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
    LEFT JOIN 
        PostBadges pb ON tp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = pb.UserId)
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.PostType,
    ps.OwnerDisplayName,
    COALESCE(ps.Comments, 'No comments') AS Comments,
    COALESCE(ps.Badges, 'No badges') AS Badges
FROM 
    PostStats ps
ORDER BY 
    ps.CreationDate DESC;
