WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
MostVotedPosts AS (
    SELECT 
        rp.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    WHERE 
        v.VoteTypeId = 2  
    GROUP BY 
        rp.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(mvp.VoteCount, 0) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MostVotedPosts mvp ON rp.PostId = mvp.PostId
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.CreationDate,
    fr.OwnerDisplayName,
    fr.VoteCount
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.VoteCount DESC
LIMIT 50;