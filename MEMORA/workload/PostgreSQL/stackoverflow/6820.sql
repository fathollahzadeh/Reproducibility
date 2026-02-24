WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.Score > 10
),
TopRankedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.Owner,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
        AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = rp.PostId)
    WHERE 
        rp.PostRank <= 5
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.Score,
        trp.Owner,
        trp.LastEditor,
        trp.LastEditDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Comments c ON trp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON trp.PostId = v.PostId
    GROUP BY 
        trp.PostId, trp.Title, trp.Score, trp.Owner, trp.LastEditor, trp.LastEditDate
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.Owner,
    pd.LastEditor,
    pd.LastEditDate,
    pd.CommentCount,
    pd.VoteCount,
    COALESCE(ROUND(pd.Score * 1.0 / NULLIF(pd.CommentCount + 1, 0), 2), 0) AS ScorePerComment
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.PostId ASC;
