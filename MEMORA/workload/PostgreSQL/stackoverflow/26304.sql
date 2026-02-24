WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        t.Count > 100 
    GROUP BY 
        t.TagName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    pta.LastEditDate,
    pta.HistoryTypes,
    pt.TagName AS PopularTag,
    pt.BadgeCount,
    pt.AvgReputation
FROM 
    RankedPosts rp
JOIN 
    PostHistoryAnalysis pta ON rp.PostId = pta.PostId
JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, ', ')) 
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.CreationDate DESC 
LIMIT 100;