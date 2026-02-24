WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.AnswerCount, u.DisplayName
),
TopTaggedPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 5 
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ttp.PostId,
    ttp.Title,
    ttp.Body,
    ttp.Tags,
    ttp.CreationDate,
    ttp.ViewCount,
    ttp.AnswerCount,
    ttp.CommentCount,
    COALESCE(pus.ChangeTypes, 'No changes') AS ChangeTypes,
    pus.LastHistoryDate
FROM 
    TopTaggedPosts ttp
LEFT JOIN 
    PostHistoryStats pus ON ttp.PostId = pus.PostId
ORDER BY 
    ttp.CreationDate DESC;