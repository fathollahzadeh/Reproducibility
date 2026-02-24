
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY COALESCE(p.LastActivityDate, p.CreationDate) DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 /* Answer posts */
    WHERE 
        p.PostTypeId = 1 /* Questions */
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' /* Consider questions from the last year */
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags
),
TopRankedPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, RecentActivityRank, Tags
    FROM 
        RankedPosts
    WHERE 
        RecentActivityRank = 1 /* Only the most recently active question for each unique question */
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerDisplayName,
    trp.Tags,
    SUBSTRING(p.Body FROM 1 FOR 300) AS ShortBody, /* Preview of Body, first 300 chars */
    COALESCE((SELECT STRING_AGG(c.Text, ' | ') 
              FROM Comments c 
              WHERE c.PostId = trp.PostId), 'No comments') AS CommentPreview
FROM 
    TopRankedPosts trp
JOIN 
    Posts p ON p.Id = trp.PostId
ORDER BY 
    trp.Title ASC;
