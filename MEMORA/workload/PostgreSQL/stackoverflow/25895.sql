WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN p.PostTypeId = 1 THEN (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) 
            ELSE 0 
        END AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2020-01-01'  
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.LastActivityDate,
    pd.CommentCount,
    pd.AnswerCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.Tags,
    CASE
        WHEN pd.UpVoteCount - pd.DownVoteCount > 0 THEN 'Positive'
        WHEN pd.UpVoteCount - pd.DownVoteCount < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    rank() OVER (ORDER BY pd.LastActivityDate DESC) AS Rank,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = pd.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)) AS EditCount
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0 
ORDER BY 
    pd.LastActivityDate DESC
LIMIT 100;