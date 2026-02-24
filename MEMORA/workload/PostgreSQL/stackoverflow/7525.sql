WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PopularUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5 AND SUM(Score) > 50
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        pu.PostCount,
        pu.TotalScore,
        pu.TotalAnswers
    FROM 
        RankedPosts rp
    JOIN 
        PopularUsers pu ON rp.OwnerUserId = pu.OwnerUserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.PostCount,
    tp.TotalScore,
    tp.TotalAnswers,
    COALESCE(pl.RelatedPostId, 0) AS RelatedPostId,
    COALESCE(pl.LinkTypeId, 0) AS LinkTypeId
FROM 
    TopPosts tp
LEFT JOIN 
    PostLinks pl ON tp.PostId = pl.PostId
ORDER BY 
    tp.TotalScore DESC, tp.PostCount DESC;
