
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.AnswerCount > 0 THEN ROUND(CAST(rp.UpVotes AS FLOAT) / (rp.UpVotes + rp.DownVotes) * 100, 2)
            ELSE 0 
        END AS UpVotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 100
)
SELECT 
    pd.Title,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.UpVotePercentage,
    COALESCE(t.TagName, 'No Tags') AS MostRelevantTag
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    Tags t ON p.Id = t.ExcerptPostId
ORDER BY 
    pd.UpVotePercentage DESC, pd.AnswerCount DESC;
