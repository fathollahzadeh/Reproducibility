WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopRanked AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 3
),
PostWithComments AS (
    SELECT 
        tr.Id AS PostId, 
        tr.Title, 
        tr.CreationDate, 
        tr.ViewCount, 
        tr.Score, 
        tr.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopRanked tr
    LEFT JOIN 
        Comments c ON tr.Id = c.PostId
    GROUP BY 
        tr.Id, tr.Title, tr.CreationDate, tr.ViewCount, tr.Score, tr.OwnerDisplayName
),
FinalResult AS (
    SELECT 
        pwc.*, 
        ROW_NUMBER() OVER (ORDER BY pwc.Score DESC, pwc.CommentCount DESC) AS FinalRank
    FROM 
        PostWithComments pwc
)
SELECT 
    fr.PostId, 
    fr.Title, 
    fr.CreationDate, 
    fr.ViewCount, 
    fr.Score, 
    fr.OwnerDisplayName, 
    fr.CommentCount, 
    fr.FinalRank
FROM 
    FinalResult fr
WHERE 
    fr.FinalRank <= 10
ORDER BY 
    fr.FinalRank;