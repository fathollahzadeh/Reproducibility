WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS CreationRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
TopQuestions AS (
    SELECT
        rp.PostId,
        rp.Title,
        u.DisplayName AS Owner,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostTypeId = 1 AND rp.Rank <= 5
),
TopAnswers AS (
    SELECT
        rp.PostId,
        rp.Title,
        u.DisplayName AS Owner,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostTypeId = 2 AND rp.Rank <= 5
),
CombinedTopPosts AS (
    SELECT 
        'Question' AS PostType,
        tq.PostId,
        tq.Title,
        tq.Owner,
        tq.Score,
        tq.ViewCount,
        tq.CreationDate
    FROM 
        TopQuestions tq
    UNION ALL
    SELECT 
        'Answer' AS PostType,
        ta.PostId,
        ta.Title,
        ta.Owner,
        ta.Score,
        ta.ViewCount,
        ta.CreationDate
    FROM 
        TopAnswers ta
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalPosts AS (
    SELECT 
        ct.*,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        CombinedTopPosts ct
    LEFT JOIN 
        PostComments pc ON ct.PostId = pc.PostId
)
SELECT 
    fp.PostType,
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.TotalComments,
    CASE 
        WHEN fp.TotalComments = 0 THEN 'No comments'
        ELSE CONCAT(fp.TotalComments, ' comments')
    END AS CommentStatus
FROM 
    FinalPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC;