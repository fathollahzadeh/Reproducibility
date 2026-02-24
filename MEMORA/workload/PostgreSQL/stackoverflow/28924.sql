
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.TagRank <= 3
),
PostAnalysis AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.OwnerDisplayName,
        COUNT(DISTINCT bh.Id) AS EditCount,
        MAX(bh.CreationDate) AS LastEditDate
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostHistory bh ON TP.PostId = bh.PostId 
        AND bh.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        TP.PostId, TP.Title, TP.OwnerDisplayName
)

SELECT 
    PA.*,
    TP.Tags,
    PA.EditCount,
    PA.LastEditDate
FROM 
    PostAnalysis PA
JOIN 
    TopPosts TP ON PA.PostId = TP.PostId
ORDER BY 
    PA.LastEditDate DESC, 
    PA.EditCount DESC;
