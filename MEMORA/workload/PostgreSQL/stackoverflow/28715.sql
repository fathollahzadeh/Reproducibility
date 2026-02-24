WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.CreationDate, ' - ', ph.Comment), '; ') AS EditHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.AnswerCount,
    rp.Upvotes,
    rp.Downvotes,
    CASE 
        WHEN rp.AnswerCount > 0 THEN 'Answered'
        ELSE 'Unanswered'
    END AS PostStatus,
    re.EditHistory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Tags, rp.AnswerCount DESC;