WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerName
    FROM RankedPosts rp
    WHERE rp.PostRank <= 10
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS TotalComments
    FROM Comments pc
    GROUP BY pc.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pc.TotalComments,
    pt.Tags,
    pp.OwnerName
FROM PopularPosts pp
LEFT JOIN PostComments pc ON pp.PostId = pc.PostId
LEFT JOIN PostTags pt ON pp.PostId = pt.PostId
ORDER BY pp.Score DESC, pp.CreationDate DESC;
