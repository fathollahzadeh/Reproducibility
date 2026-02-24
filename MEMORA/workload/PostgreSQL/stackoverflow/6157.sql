WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        t.TagName,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON t.Id = pl.RelatedPostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id AND PostHistoryTypeId IN (4, 5, 6) 
        )
    WHERE 
        p.PostTypeId = 1
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (PARTITION BY pd.TagName ORDER BY pd.Score DESC) AS RankByScore,
        DENSE_RANK() OVER (PARTITION BY pd.TagName ORDER BY pd.LastActivityDate DESC) AS RankByActivity
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.TagName,
    rp.LastEditor,
    rp.LastEditDate,
    rp.RankByScore,
    rp.RankByActivity
FROM 
    RankedPosts rp
WHERE 
    rp.RankByScore <= 5
    OR rp.RankByActivity <= 5
ORDER BY 
    rp.TagName, rp.Score DESC;
