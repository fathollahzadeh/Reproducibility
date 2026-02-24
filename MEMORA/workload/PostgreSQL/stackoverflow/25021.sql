
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
)

SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.AnswerCount,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Active'
        WHEN rp.AnswerCount > 0 THEN 'Responded'
        ELSE 'Unanswered'
    END AS PostStatus,
    CASE 
        WHEN (rp.TotalUpVotes - rp.TotalDownVotes) > 0 THEN 'Positive Feedback'
        WHEN (rp.TotalUpVotes - rp.TotalDownVotes) < 0 THEN 'Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackSummary
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5  
ORDER BY 
    rp.OwnerDisplayName, 
    rp.CreationDate DESC;
