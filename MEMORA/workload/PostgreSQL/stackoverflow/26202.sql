WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.Tags,
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1 
),
CommentStatistics AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostWithComments AS (
    SELECT 
        tp.*,
        cs.CommentCount,
        cs.LastCommentDate
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentStatistics cs ON tp.PostId = cs.PostId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Body,
    pwc.Tags,
    pwc.OwnerDisplayName,
    pwc.CreationDate,
    pwc.Score,
    COALESCE(pwc.CommentCount, 0) AS TotalComments,
    pwc.LastCommentDate,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM 
    PostWithComments pwc
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = pwc.PostId)
GROUP BY 
    pwc.PostId, pwc.Title, pwc.Body, pwc.Tags, pwc.OwnerDisplayName, 
    pwc.CreationDate, pwc.Score, pwc.CommentCount, pwc.LastCommentDate
ORDER BY 
    pwc.Score DESC, pwc.CreationDate DESC
LIMIT 50;