
WITH PostTagProcessing AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>'), 1) AS TagCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalBenchmarking AS (
    SELECT 
        ptp.PostId,
        ptp.Title,
        ptp.TagCount,
        ptp.CommentCount,
        pha.LastEditDate,
        pha.CloseCount,
        pha.EditCount,
        pha.UniqueEditors,
        ptp.TotalBounty,
        (COALESCE(ptp.CommentCount, 0) + COALESCE(pha.EditCount, 0))::float / NULLIF(ptp.TagCount, 0) AS InteractionToTagRatio 
    FROM 
        PostTagProcessing ptp
    JOIN 
        PostHistoryAnalysis pha ON ptp.PostId = pha.PostId
    ORDER BY 
        ptp.TagCount DESC, 
        ptp.CommentCount DESC
)
SELECT 
    *,
    CASE 
        WHEN InteractionToTagRatio > 2 THEN 'Highly Interactive'
        WHEN InteractionToTagRatio BETWEEN 1 AND 2 THEN 'Moderately Interactive'
        ELSE 'Less Interactive'
    END AS InteractionCategory
FROM 
    FinalBenchmarking
WHERE 
    TagCount >= 3
