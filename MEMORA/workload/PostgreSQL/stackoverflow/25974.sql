WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Tags,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 /* Filtering for Questions */
),
PopularTags AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 /* Get top 5 posts for each tag */
    GROUP BY 
        Tags
    ORDER BY 
        QuestionCount DESC
    LIMIT 10 /* Get top 10 tags by question count */
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EventCount,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS UsersInvolved
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 /* Focusing on Questions */
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    rp.Owner,
    pt.QuestionCount,
    phs.EventCount,
    phs.UsersInvolved
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Tags = pt.Tags
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.TagRank <= 5
ORDER BY 
    pt.QuestionCount DESC,
    rp.Score DESC;
