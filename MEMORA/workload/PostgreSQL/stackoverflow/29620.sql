WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS CommentText
    FROM 
        Comments c
    JOIN 
        FilteredPosts fp ON c.PostId = fp.PostId
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    GROUP BY 
        b.UserId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.ViewCount,
    pc.CommentCount,
    pc.CommentText,
    pb.BadgeCount,
    pb.BadgeNames
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostComments pc ON fp.PostId = pc.PostId
LEFT JOIN 
    PostBadges pb ON pb.UserId = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = fp.PostId
    )
ORDER BY 
    fp.CreationDate DESC;