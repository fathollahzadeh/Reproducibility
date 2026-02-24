
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.LastActivityDate DESC) AS OverallRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.LastActivityDate
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS Comments,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (1, 4, 10)) AS TitleEdits,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 12) AS DeleteVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        pha.Comments,
        pha.TitleEdits,
        pha.DeleteVotes,
        CASE 
            WHEN rp.OwnerPostRank = 1 THEN 'Latest Post'
            WHEN rp.OverallRank <= 10 THEN 'Top Ranked'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregate pha ON rp.Id = pha.PostId
)
SELECT 
    *,
    CASE 
        WHEN PostCategory = 'Top Ranked' AND AnswerCount > 0 THEN 'Highly Active'
        WHEN AnswerCount = 0 AND Score < 0 THEN 'Needs Attention'
        ELSE 'Normal'
    END AS AdditionalCategory
FROM 
    FinalResults
WHERE 
    ViewCount > 50
ORDER BY 
    CreationDate DESC, Score DESC;
