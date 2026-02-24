
WITH ActiveQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.ClosedDate IS NULL 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    aq.PostId,
    aq.Title,
    aq.Body,
    aq.Tags,
    aq.OwnerDisplayName,
    aq.AnswerCount,
    aq.CommentCount,
    aq.UpVotes,
    aq.DownVotes,
    aq.CreationDate,
    re.LastEditDate,
    re.Editors,
    re.EditComments
FROM 
    ActiveQuestions aq
LEFT JOIN 
    RecentEdits re ON aq.PostId = re.PostId
ORDER BY 
    aq.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
