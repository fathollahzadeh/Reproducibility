WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RevisionOrder
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1  
),
AggregatedVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, ' | ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.Body,
    pi.CreationDate,
    pi.ViewCount,
    pi.Score,
    pi.OwnerDisplayName,
    ag.UpVotes,
    ag.DownVotes,
    phd.EditComments,
    phd.LastEditDate,
    phd.FirstEditDate,
    phd.EditCount
FROM 
    PostInfo pi
LEFT JOIN 
    AggregatedVotes ag ON pi.PostId = ag.PostId
LEFT JOIN 
    PostHistoryDetails phd ON pi.PostId = phd.PostId
WHERE 
    pi.RevisionOrder = 1  
ORDER BY 
    pi.CreationDate DESC
LIMIT 100;